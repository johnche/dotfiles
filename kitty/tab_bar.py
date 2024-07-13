import math
import socket
import subprocess
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional

from kittens.ssh.utils import get_connection_data

from kitty.boss import Boss
from kitty.fast_data_types import Color, Screen, get_boss, get_options
from kitty.tab_bar import Dict, DrawData, ExtraData, TabBarData, as_rgb, draw_title
from kitty.utils import color_as_int
from kitty.window import Window

# Copyright (C) 2006-2007  Robey Pointer <robeypointer@gmail.com>
# Copyright (C) 2012  Olle Lundberg <geek@nerd.sh>
#
# This file is part of paramiko.
#
# Paramiko is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
#
# Paramiko is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Paramiko; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.

"""
Configuration file (aka ``ssh_config``) support.
"""

import fnmatch
import getpass
import os
import re
import shlex
import socket
from hashlib import sha1
from io import StringIO
from functools import partial

invoke, invoke_import_error = None, None
try:
    import invoke
except ImportError as e:
    invoke_import_error = e


class SSHException(Exception):
    """
    Exception raised by failures in SSH2 protocol negotiation or logic errors.
    """

    pass


class AuthenticationException(SSHException):
    """
    Exception raised when authentication failed for some reason.  It may be
    possible to retry with different credentials.  (Other classes specify more
    specific reasons.)

    .. versionadded:: 1.6
    """

    pass


class PasswordRequiredException(AuthenticationException):
    """
    Exception raised when a password is needed to unlock a private key file.
    """

    pass


class BadAuthenticationType(AuthenticationException):
    """
    Exception raised when an authentication type (like password) is used, but
    the server isn't allowing that type.  (It may only allow public-key, for
    example.)

    .. versionadded:: 1.1
    """

    allowed_types = []

    # TODO 4.0: remove explanation kwarg
    def __init__(self, explanation, types):
        # TODO 4.0: remove this supercall unless it's actually required for
        # pickling (after fixing pickling)
        AuthenticationException.__init__(self, explanation, types)
        self.explanation = explanation
        self.allowed_types = types

    def __str__(self):
        return "{}; allowed types: {!r}".format(
            self.explanation, self.allowed_types
        )


class PartialAuthentication(AuthenticationException):
    """
    An internal exception thrown in the case of partial authentication.
    """

    allowed_types = []

    def __init__(self, types):
        AuthenticationException.__init__(self, types)
        self.allowed_types = types

    def __str__(self):
        return "Partial authentication; allowed types: {!r}".format(
            self.allowed_types
        )


# TODO 4.0: stop inheriting from SSHException, move to auth.py
class UnableToAuthenticate(AuthenticationException):
    pass


class ChannelException(SSHException):
    """
    Exception raised when an attempt to open a new `.Channel` fails.

    :param int code: the error code returned by the server

    .. versionadded:: 1.6
    """

    def __init__(self, code, text):
        SSHException.__init__(self, code, text)
        self.code = code
        self.text = text

    def __str__(self):
        return "ChannelException({!r}, {!r})".format(self.code, self.text)


class BadHostKeyException(SSHException):
    """
    The host key given by the SSH server did not match what we were expecting.

    :param str hostname: the hostname of the SSH server
    :param PKey got_key: the host key presented by the server
    :param PKey expected_key: the host key expected

    .. versionadded:: 1.6
    """

    def __init__(self, hostname, got_key, expected_key):
        SSHException.__init__(self, hostname, got_key, expected_key)
        self.hostname = hostname
        self.key = got_key
        self.expected_key = expected_key

    def __str__(self):
        msg = "Host key for server '{}' does not match: got '{}', expected '{}'"  # noqa
        return msg.format(
            self.hostname,
            self.key.get_base64(),
            self.expected_key.get_base64(),
        )


class IncompatiblePeer(SSHException):
    """
    A disagreement arose regarding an algorithm required for key exchange.

    .. versionadded:: 2.9
    """

    # TODO 4.0: consider making this annotate w/ 1..N 'missing' algorithms,
    # either just the first one that would halt kex, or even updating the
    # Transport logic so we record /all/ that /could/ halt kex.
    # TODO: update docstrings where this may end up raised so they are more
    # specific.
    pass


class ProxyCommandFailure(SSHException):
    """
    The "ProxyCommand" found in the .ssh/config file returned an error.

    :param str command: The command line that is generating this exception.
    :param str error: The error captured from the proxy command output.
    """

    def __init__(self, command, error):
        SSHException.__init__(self, command, error)
        self.command = command
        self.error = error

    def __str__(self):
        return 'ProxyCommand("{}") returned nonzero exit status: {}'.format(
            self.command, self.error
        )


class NoValidConnectionsError(socket.error):
    """
    Multiple connection attempts were made and no families succeeded.

    This exception class wraps multiple "real" underlying connection errors,
    all of which represent failed connection attempts. Because these errors are
    not guaranteed to all be of the same error type (i.e. different errno,
    `socket.error` subclass, message, etc) we expose a single unified error
    message and a ``None`` errno so that instances of this class match most
    normal handling of `socket.error` objects.

    To see the wrapped exception objects, access the ``errors`` attribute.
    ``errors`` is a dict whose keys are address tuples (e.g. ``('127.0.0.1',
    22)``) and whose values are the exception encountered trying to connect to
    that address.

    It is implied/assumed that all the errors given to a single instance of
    this class are from connecting to the same hostname + port (and thus that
    the differences are in the resolution of the hostname - e.g. IPv4 vs v6).

    .. versionadded:: 1.16
    """

    def __init__(self, errors):
        """
        :param dict errors:
            The errors dict to store, as described by class docstring.
        """
        addrs = sorted(errors.keys())
        body = ", ".join([x[0] for x in addrs[:-1]])
        tail = addrs[-1][0]
        if body:
            msg = "Unable to connect to port {0} on {1} or {2}"
        else:
            msg = "Unable to connect to port {0} on {2}"
        super().__init__(
            None, msg.format(addrs[0][1], body, tail)  # stand-in for errno
        )
        self.errors = errors

    def __reduce__(self):
        return (self.__class__, (self.errors,))


class CouldNotCanonicalize(SSHException):
    """
    Raised when hostname canonicalization fails & fallback is disabled.

    .. versionadded:: 2.7
    """

    pass


class ConfigParseError(SSHException):
    """
    A fatal error was encountered trying to parse SSH config data.

    Typically this means a config file violated the ``ssh_config``
    specification in a manner that requires exiting immediately, such as not
    matching ``key = value`` syntax or misusing certain ``Match`` keywords.

    .. versionadded:: 2.7
    """

    pass


class MessageOrderError(SSHException):
    """
    Out-of-order protocol messages were received, violating "strict kex" mode.

    .. versionadded:: 3.4
    """

    pass


SSH_PORT = 22


class SSHConfig:
    """
    Representation of config information as stored in the format used by
    OpenSSH. Queries can be made via `lookup`. The format is described in
    OpenSSH's ``ssh_config`` man page. This class is provided primarily as a
    convenience to posix users (since the OpenSSH format is a de-facto
    standard on posix) but should work fine on Windows too.

    .. versionadded:: 1.6
    """

    SETTINGS_REGEX = re.compile(r"(\w+)(?:\s*=\s*|\s+)(.+)")

    # TODO: do a full scan of ssh.c & friends to make sure we're fully
    # compatible across the board, e.g. OpenSSH 8.1 added %n to ProxyCommand.
    TOKENS_BY_CONFIG_KEY = {
        "controlpath": ["%C", "%h", "%l", "%L", "%n", "%p", "%r", "%u"],
        "hostname": ["%h"],
        "identityfile": ["%C", "~", "%d", "%h", "%l", "%u", "%r"],
        "proxycommand": ["~", "%h", "%p", "%r"],
        "proxyjump": ["%h", "%p", "%r"],
        # Doesn't seem worth making this 'special' for now, it will fit well
        # enough (no actual match-exec config key to be confused with).
        "match-exec": ["%C", "%d", "%h", "%L", "%l", "%n", "%p", "%r", "%u"],
    }

    def __init__(self):
        """
        Create a new OpenSSH config object.

        Note: the newer alternate constructors `from_path`, `from_file` and
        `from_text` are simpler to use, as they parse on instantiation. For
        example, instead of::

            config = SSHConfig()
            config.parse(open("some-path.config")

        you could::

            config = SSHConfig.from_file(open("some-path.config"))
            # Or more directly:
            config = SSHConfig.from_path("some-path.config")
            # Or if you have arbitrary ssh_config text from some other source:
            config = SSHConfig.from_text("Host foo\\n\\tUser bar")
        """
        self._config = []

    @classmethod
    def from_text(cls, text):
        """
        Create a new, parsed `SSHConfig` from ``text`` string.

        .. versionadded:: 2.7
        """
        return cls.from_file(StringIO(text))

    @classmethod
    def from_path(cls, path):
        """
        Create a new, parsed `SSHConfig` from the file found at ``path``.

        .. versionadded:: 2.7
        """
        with open(path) as flo:
            return cls.from_file(flo)

    @classmethod
    def from_file(cls, flo):
        """
        Create a new, parsed `SSHConfig` from file-like object ``flo``.

        .. versionadded:: 2.7
        """
        obj = cls()
        obj.parse(flo)
        return obj

    def parse(self, file_obj):
        """
        Read an OpenSSH config from the given file object.

        :param file_obj: a file-like object to read the config file from
        """
        # Start out w/ implicit/anonymous global host-like block to hold
        # anything not contained by an explicit one.
        context = {"host": ["*"], "config": {}}
        for line in file_obj:
            # Strip any leading or trailing whitespace from the line.
            # Refer to https://github.com/paramiko/paramiko/issues/499
            line = line.strip()
            # Skip blanks, comments
            if not line or line.startswith("#"):
                continue

            # Parse line into key, value
            match = re.match(self.SETTINGS_REGEX, line)
            if not match:
                raise ConfigParseError("Unparsable line {}".format(line))
            key = match.group(1).lower()
            value = match.group(2)

            # Host keyword triggers switch to new block/context
            if key in ("host", "match"):
                self._config.append(context)
                context = {"config": {}}
                if key == "host":
                    # TODO 4.0: make these real objects or at least name this
                    # "hosts" to acknowledge it's an iterable. (Doing so prior
                    # to 3.0, despite it being a private API, feels bad -
                    # surely such an old codebase has folks actually relying on
                    # these keys.)
                    context["host"] = self._get_hosts(value)
                else:
                    context["matches"] = self._get_matches(value)
            # Special-case for noop ProxyCommands
            elif key == "proxycommand" and value.lower() == "none":
                # Store 'none' as None - not as a string implying that the
                # proxycommand is the literal shell command "none"!
                context["config"][key] = None
            # All other keywords get stored, directly or via append
            else:
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]

                # identityfile, localforward, remoteforward keys are special
                # cases, since they are allowed to be specified multiple times
                # and they should be tried in order of specification.
                if key in ["identityfile", "localforward", "remoteforward"]:
                    if key in context["config"]:
                        context["config"][key].append(value)
                    else:
                        context["config"][key] = [value]
                elif key not in context["config"]:
                    context["config"][key] = value
        # Store last 'open' block and we're done
        self._config.append(context)

    def lookup(self, hostname):
        """
        Return a dict (`SSHConfigDict`) of config options for a given hostname.

        The host-matching rules of OpenSSH's ``ssh_config`` man page are used:
        For each parameter, the first obtained value will be used.  The
        configuration files contain sections separated by ``Host`` and/or
        ``Match`` specifications, and that section is only applied for hosts
        which match the given patterns or keywords

        Since the first obtained value for each parameter is used, more host-
        specific declarations should be given near the beginning of the file,
        and general defaults at the end.

        The keys in the returned dict are all normalized to lowercase (look for
        ``"port"``, not ``"Port"``. The values are processed according to the
        rules for substitution variable expansion in ``ssh_config``.

        Finally, please see the docs for `SSHConfigDict` for deeper info on
        features such as optional type conversion methods, e.g.::

            conf = my_config.lookup('myhost')
            assert conf['passwordauthentication'] == 'yes'
            assert conf.as_bool('passwordauthentication') is True

        .. note::
            If there is no explicitly configured ``HostName`` value, it will be
            set to the being-looked-up hostname, which is as close as we can
            get to OpenSSH's behavior around that particular option.

        :param str hostname: the hostname to lookup

        .. versionchanged:: 2.5
            Returns `SSHConfigDict` objects instead of dict literals.
        .. versionchanged:: 2.7
            Added canonicalization support.
        .. versionchanged:: 2.7
            Added ``Match`` support.
        .. versionchanged:: 3.3
            Added ``Match final`` support.
        """
        # First pass
        options = self._lookup(hostname=hostname)
        # Inject HostName if it was not set (this used to be done incidentally
        # during tokenization, for some reason).
        if "hostname" not in options:
            options["hostname"] = hostname
        # Handle canonicalization
        canon = options.get("canonicalizehostname", None) in ("yes", "always")
        maxdots = int(options.get("canonicalizemaxdots", 1))
        if canon and hostname.count(".") <= maxdots:
            # NOTE: OpenSSH manpage does not explicitly state this, but its
            # implementation for CanonicalDomains is 'split on any whitespace'.
            domains = options["canonicaldomains"].split()
            hostname = self.canonicalize(hostname, options, domains)
            # Overwrite HostName again here (this is also what OpenSSH does)
            options["hostname"] = hostname
            options = self._lookup(
                hostname, options, canonical=True, final=True
            )
        else:
            options = self._lookup(
                hostname, options, canonical=False, final=True
            )
        return options

    def _lookup(self, hostname, options=None, canonical=False, final=False):
        # Init
        if options is None:
            options = SSHConfigDict()
        # Iterate all stanzas, applying any that match, in turn (so that things
        # like Match can reference currently understood state)
        for context in self._config:
            if not (
                self._pattern_matches(context.get("host", []), hostname)
                or self._does_match(
                    context.get("matches", []),
                    hostname,
                    canonical,
                    final,
                    options,
                )
            ):
                continue
            for key, value in context["config"].items():
                if key not in options:
                    # Create a copy of the original value,
                    # else it will reference the original list
                    # in self._config and update that value too
                    # when the extend() is being called.
                    options[key] = value[:] if value is not None else value
                elif key == "identityfile":
                    options[key].extend(
                        x for x in value if x not in options[key]
                    )
        if final:
            # Expand variables in resulting values
            # (besides 'Match exec' which was already handled above)
            options = self._expand_variables(options, hostname)
        return options

    def canonicalize(self, hostname, options, domains):
        """
        Return canonicalized version of ``hostname``.

        :param str hostname: Target hostname.
        :param options: An `SSHConfigDict` from a previous lookup pass.
        :param domains: List of domains (e.g. ``["paramiko.org"]``).

        :returns: A canonicalized hostname if one was found, else ``None``.

        .. versionadded:: 2.7
        """
        found = False
        for domain in domains:
            candidate = "{}.{}".format(hostname, domain)
            family_specific = _addressfamily_host_lookup(candidate, options)
            if family_specific is not None:
                # TODO: would we want to dig deeper into other results? e.g. to
                # find something that satisfies PermittedCNAMEs when that is
                # implemented?
                found = family_specific[0]
            else:
                # TODO: what does ssh use here and is there a reason to use
                # that instead of gethostbyname?
                try:
                    found = socket.gethostbyname(candidate)
                except socket.gaierror:
                    pass
            if found:
                # TODO: follow CNAME (implied by found != candidate?) if
                # CanonicalizePermittedCNAMEs allows it
                return candidate
        # If we got here, it means canonicalization failed.
        # When CanonicalizeFallbackLocal is undefined or 'yes', we just spit
        # back the original hostname.
        if options.get("canonicalizefallbacklocal", "yes") == "yes":
            return hostname
        # And here, we failed AND fallback was set to a non-yes value, so we
        # need to get mad.
        raise CouldNotCanonicalize(hostname)

    def get_hostnames(self):
        """
        Return the set of literal hostnames defined in the SSH config (both
        explicit hostnames and wildcard entries).
        """
        hosts = set()
        for entry in self._config:
            hosts.update(entry["host"])
        return hosts

    def _pattern_matches(self, patterns, target):
        # Convenience auto-splitter if not already a list
        if hasattr(patterns, "split"):
            patterns = patterns.split(",")
        match = False
        for pattern in patterns:
            # Short-circuit if target matches a negated pattern
            if pattern.startswith("!") and fnmatch.fnmatch(
                target, pattern[1:]
            ):
                return False
            # Flag a match, but continue (in case of later negation) if regular
            # match occurs
            elif fnmatch.fnmatch(target, pattern):
                match = True
        return match

    def _does_match(
        self, match_list, target_hostname, canonical, final, options
    ):
        matched = []
        candidates = match_list[:]
        local_username = getpass.getuser()
        while candidates:
            candidate = candidates.pop(0)
            passed = None
            # Obtain latest host/user value every loop, so later Match may
            # reference values assigned within a prior Match.
            configured_host = options.get("hostname", None)
            configured_user = options.get("user", None)
            type_, param = candidate["type"], candidate["param"]
            # Canonical is a hard pass/fail based on whether this is a
            # canonicalized re-lookup.
            if type_ == "canonical":
                if self._should_fail(canonical, candidate):
                    return False
            if type_ == "final":
                passed = final
            # The parse step ensures we only see this by itself or after
            # canonical, so it's also an easy hard pass. (No negation here as
            # that would be uh, pretty weird?)
            elif type_ == "all":
                return True
            # From here, we are testing various non-hard criteria,
            # short-circuiting only on fail
            elif type_ == "host":
                hostval = configured_host or target_hostname
                passed = self._pattern_matches(param, hostval)
            elif type_ == "originalhost":
                passed = self._pattern_matches(param, target_hostname)
            elif type_ == "user":
                user = configured_user or local_username
                passed = self._pattern_matches(param, user)
            elif type_ == "localuser":
                passed = self._pattern_matches(param, local_username)
            elif type_ == "exec":
                exec_cmd = self._tokenize(
                    options, target_hostname, "match-exec", param
                )
                # This is the laziest spot in which we can get mad about an
                # inability to import Invoke.
                if invoke is None:
                    raise invoke_import_error
                # Like OpenSSH, we 'redirect' stdout but let stderr bubble up
                passed = invoke.run(exec_cmd, hide="stdout", warn=True).ok
            # Tackle any 'passed, but was negated' results from above
            if passed is not None and self._should_fail(passed, candidate):
                return False
            # Made it all the way here? Everything matched!
            matched.append(candidate)
        # Did anything match? (To be treated as bool, usually.)
        return matched

    def _should_fail(self, would_pass, candidate):
        return would_pass if candidate["negate"] else not would_pass

    def _tokenize(self, config, target_hostname, key, value):
        """
        Tokenize a string based on current config/hostname data.

        :param config: Current config data.
        :param target_hostname: Original target connection hostname.
        :param key: Config key being tokenized (used to filter token list).
        :param value: Config value being tokenized.

        :returns: The tokenized version of the input ``value`` string.
        """
        allowed_tokens = self._allowed_tokens(key)
        # Short-circuit if no tokenization possible
        if not allowed_tokens:
            return value
        # Obtain potentially configured hostname, for use with %h.
        # Special-case where we are tokenizing the hostname itself, to avoid
        # replacing %h with a %h-bearing value, etc.
        configured_hostname = target_hostname
        if key != "hostname":
            configured_hostname = config.get("hostname", configured_hostname)
        # Ditto the rest of the source values
        if "port" in config:
            port = config["port"]
        else:
            port = SSH_PORT
        user = getpass.getuser()
        if "user" in config:
            remoteuser = config["user"]
        else:
            remoteuser = user
        local_hostname = socket.gethostname().split(".")[0]
        local_fqdn = LazyFqdn(config, local_hostname)
        homedir = os.path.expanduser("~")
        tohash = local_hostname + target_hostname + repr(port) + remoteuser
        # The actual tokens!
        replacements = {
            # TODO: %%???
            "%C": sha1(tohash.encode()).hexdigest(),
            "%d": homedir,
            "%h": configured_hostname,
            # TODO: %i?
            "%L": local_hostname,
            "%l": local_fqdn,
            # also this is pseudo buggy when not in Match exec mode so document
            # that. also WHY is that the case?? don't we do all of this late?
            "%n": target_hostname,
            "%p": port,
            "%r": remoteuser,
            # TODO: %T? don't believe this is possible however
            "%u": user,
            "~": homedir,
        }
        # Do the thing with the stuff
        tokenized = value
        for find, replace in replacements.items():
            if find not in allowed_tokens:
                continue
            tokenized = tokenized.replace(find, str(replace))
        # TODO: log? eg that value -> tokenized
        return tokenized

    def _allowed_tokens(self, key):
        """
        Given config ``key``, return list of token strings to tokenize.

        .. note::
            This feels like it wants to eventually go away, but is used to
            preserve as-strict-as-possible compatibility with OpenSSH, which
            for whatever reason only applies some tokens to some config keys.
        """
        return self.TOKENS_BY_CONFIG_KEY.get(key, [])

    def _expand_variables(self, config, target_hostname):
        """
        Return a dict of config options with expanded substitutions
        for a given original & current target hostname.

        Please refer to :doc:`/api/config` for details.

        :param dict config: the currently parsed config
        :param str hostname: the hostname whose config is being looked up
        """
        for k in config:
            if config[k] is None:
                continue
            tokenizer = partial(self._tokenize, config, target_hostname, k)
            if isinstance(config[k], list):
                for i, value in enumerate(config[k]):
                    config[k][i] = tokenizer(value)
            else:
                config[k] = tokenizer(config[k])
        return config

    def _get_hosts(self, host):
        """
        Return a list of host_names from host value.
        """
        try:
            return shlex.split(host)
        except ValueError:
            raise ConfigParseError("Unparsable host {}".format(host))

    def _get_matches(self, match):
        """
        Parse a specific Match config line into a list-of-dicts for its values.

        Performs some parse-time validation as well.
        """
        matches = []
        tokens = shlex.split(match)
        while tokens:
            match = {"type": None, "param": None, "negate": False}
            type_ = tokens.pop(0)
            # Handle per-keyword negation
            if type_.startswith("!"):
                match["negate"] = True
                type_ = type_[1:]
            match["type"] = type_
            # all/canonical have no params (everything else does)
            if type_ in ("all", "canonical", "final"):
                matches.append(match)
                continue
            if not tokens:
                raise ConfigParseError(
                    "Missing parameter to Match '{}' keyword".format(type_)
                )
            match["param"] = tokens.pop(0)
            matches.append(match)
        # Perform some (easier to do now than in the middle) validation that is
        # better handled here than at lookup time.
        keywords = [x["type"] for x in matches]
        if "all" in keywords:
            allowable = ("all", "canonical")
            ok, bad = (
                list(filter(lambda x: x in allowable, keywords)),
                list(filter(lambda x: x not in allowable, keywords)),
            )
            err = None
            if any(bad):
                err = "Match does not allow 'all' mixed with anything but 'canonical'"  # noqa
            elif "canonical" in ok and ok.index("canonical") > ok.index("all"):
                err = "Match does not allow 'all' before 'canonical'"
            if err is not None:
                raise ConfigParseError(err)
        return matches


def _addressfamily_host_lookup(hostname, options):
    """
    Try looking up ``hostname`` in an IPv4 or IPv6 specific manner.

    This is an odd duck due to needing use in two divergent use cases. It looks
    up ``AddressFamily`` in ``options`` and if it is ``inet`` or ``inet6``,
    this function uses `socket.getaddrinfo` to perform a family-specific
    lookup, returning the result if successful.

    In any other situation -- lookup failure, or ``AddressFamily`` being
    unspecified or ``any`` -- ``None`` is returned instead and the caller is
    expected to do something situation-appropriate like calling
    `socket.gethostbyname`.

    :param str hostname: Hostname to look up.
    :param options: `SSHConfigDict` instance w/ parsed options.
    :returns: ``getaddrinfo``-style tuples, or ``None``, depending.
    """
    address_family = options.get("addressfamily", "any").lower()
    if address_family == "any":
        return
    try:
        family = socket.AF_INET6
        if address_family == "inet":
            family = socket.AF_INET
        return socket.getaddrinfo(
            hostname,
            None,
            family,
            socket.SOCK_DGRAM,
            socket.IPPROTO_IP,
            socket.AI_CANONNAME,
        )
    except socket.gaierror:
        pass


class LazyFqdn:
    """
    Returns the host's fqdn on request as string.
    """

    def __init__(self, config, host=None):
        self.fqdn = None
        self.config = config
        self.host = host

    def __str__(self):
        if self.fqdn is None:
            #
            # If the SSH config contains AddressFamily, use that when
            # determining  the local host's FQDN. Using socket.getfqdn() from
            # the standard library is the most general solution, but can
            # result in noticeable delays on some platforms when IPv6 is
            # misconfigured or not available, as it calls getaddrinfo with no
            # address family specified, so both IPv4 and IPv6 are checked.
            #

            # Handle specific option
            fqdn = None
            results = _addressfamily_host_lookup(self.host, self.config)
            if results is not None:
                for res in results:
                    af, socktype, proto, canonname, sa = res
                    if canonname and "." in canonname:
                        fqdn = canonname
                        break
            # Handle 'any' / unspecified / lookup failure
            if fqdn is None:
                fqdn = socket.getfqdn()
            # Cache
            self.fqdn = fqdn
        return self.fqdn


class SSHConfigDict(dict):
    """
    A dictionary wrapper/subclass for per-host configuration structures.

    This class introduces some usage niceties for consumers of `SSHConfig`,
    specifically around the issue of variable type conversions: normal value
    access yields strings, but there are now methods such as `as_bool` and
    `as_int` that yield casted values instead.

    For example, given the following ``ssh_config`` file snippet::

        Host foo.example.com
            PasswordAuthentication no
            Compression yes
            ServerAliveInterval 60

    the following code highlights how you can access the raw strings as well as
    usefully Python type-casted versions (recalling that keys are all
    normalized to lowercase first)::

        my_config = SSHConfig()
        my_config.parse(open('~/.ssh/config'))
        conf = my_config.lookup('foo.example.com')

        assert conf['passwordauthentication'] == 'no'
        assert conf.as_bool('passwordauthentication') is False
        assert conf['compression'] == 'yes'
        assert conf.as_bool('compression') is True
        assert conf['serveraliveinterval'] == '60'
        assert conf.as_int('serveraliveinterval') == 60

    .. versionadded:: 2.5
    """

    def as_bool(self, key):
        """
        Express given key's value as a boolean type.

        Typically, this is used for ``ssh_config``'s pseudo-boolean values
        which are either ``"yes"`` or ``"no"``. In such cases, ``"yes"`` yields
        ``True`` and any other value becomes ``False``.

        .. note::
            If (for whatever reason) the stored value is already boolean in
            nature, it's simply returned.

        .. versionadded:: 2.5
        """
        val = self[key]
        if isinstance(val, bool):
            return val
        return val.lower() == "yes"

    def as_int(self, key):
        """
        Express given key's value as an integer, if possible.

        This method will raise ``ValueError`` or similar if the value is not
        int-appropriate, same as the builtin `int` type.

        .. versionadded:: 2.5
        """
        return int(self[key])
# ========================================================================

# Path to SSH config file (should be standard), needed to lookup host names and retrieve
# corresponding user names
SSH_CONFIG_FILE = "~/.ssh/config"

# Whether to add padding to title of tabs
PADDED_TABS = False

# Whether to draw a separator between tabs
DRAW_SOFT_SEP = True

# Whether to draw right-hand side status information inside of filled shapes
RHS_STATUS_FILLED = True

# Separators and status icons
LEFT_SEP = ""
RIGHT_SEP = ""
SOFT_SEP = "│"
PADDING = " "
BRANCH_ICON = "󰘬"
ELLIPSIS = "…"
USER_ICON = ""
HOST_ICON = "󱡶"
PAGER_ICON = "󰦪"

# Colors
SOFT_SEP_COLOR = Color(89, 89, 89)
FILLED_ICON_BG_COLOR = Color(89, 89, 89)
ACCENTED_BG_COLOR = Color(30, 104, 199)
ACCENTED_ICON_BG_COLOR = Color(53, 132, 228)

MAX_BRANCH_LEN = 21

MIN_TAB_LEN = (
    len(LEFT_SEP)
    + len(RIGHT_SEP)
    + len(PADDING) * 2 * PADDED_TABS  # separators
    + 1  # padding
    + 1
    + 1
    + 1
    + 1  # tab symbol, space, index number, space  # one title character
)


class Button:
    def __init__(self, first_cell: int, last_cell: int, action: Callable):
        self.first_cell = first_cell
        self.last_cell = last_cell
        self.action = action

    def do_action(self) -> None:
        self.action()


buttons: List[Button] = []


def _draw_element(
    title: DrawData | str,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    colors: Dict[str, int],
    filled: bool = False,
    padded: bool = False,
    accented: bool = False,
    icon: Optional[str] = None,
    soft_sep: Optional[str] = None,
) -> int:
    # When max_tab_length < MIN_TAB_LEN, we just draw an ellipsis, without separators or
    # anything else, so that it's clear that one either needs a larger max_tab_length,
    # or another tab bar design
    if max_tab_length < MIN_TAB_LEN:
        screen.draw("…".center(max_tab_length))
        return screen.cursor.x

    if accented:
        text_fg = colors["accented_fg"]
        text_bg = colors["accented_bg"]
        icon_bg = colors["accented_icon_bg"]
    elif filled:
        text_fg = colors["filled_fg"]
        text_bg = colors["filled_bg"]
        icon_bg = colors["filled_icon_bg"] if icon else colors["filled_bg"]
    else:
        text_fg = colors["fg"]
        text_bg = colors["bg"]
        icon_bg = colors["bg"]

    components = list()

    # Left separator
    components.append((LEFT_SEP, icon_bg, colors["bg"]))
    # Padding between left separator and rest of tab
    if padded:
        components.append((PADDING, text_fg, text_bg))
    # Icon, with padding on the right if there's a tab title, and more padding before
    # title if the tab is filled and there's a tab title
    if icon:
        icon_padding = PADDING if title != "" else ""
        components.append((f"{icon}{icon_padding}", text_fg, icon_bg))
        if filled and title != "":
            components.append((PADDING, text_fg, text_bg))
    # Title
    components.append((title, text_fg, text_bg))
    # Padding between tab content and right separator
    if padded:
        components.append((PADDING, text_fg, text_bg))
    # Right separator, which is drawn using the same colors as the left separator in
    # case there isn't a tab title
    right_sep_fg = text_bg if title != "" else icon_bg
    components.append((RIGHT_SEP, right_sep_fg, colors["bg"]))
    # Inter-tab soft separator
    if soft_sep:
        components.append((soft_sep, colors["soft_sep_fg"], colors["bg"]))

    for c in components:
        screen.cursor.fg = c[1]
        screen.cursor.bg = c[2]
        if isinstance(c[0], str):
            screen.draw(c[0])
        else:
            draw_title(c[0], screen, tab, index)
            max_cursor_x = before + max_tab_length - len(LEFT_SEP) - len(PADDING)
            if screen.cursor.x > max_cursor_x:
                screen.cursor.x = max_cursor_x - 1
                screen.draw("…")

    # Element ends before soft separator
    end = screen.cursor.x - (len(soft_sep) if soft_sep else 0)
    return end


def _calc_elements_len(elements: List[Dict[str, Any]]) -> int:
    elements_len = 0
    for element in elements:
        title, icon = element["title"], element["icon"]
        # Icon
        elements_len += len(icon)
        # Icon padding, if element has a title
        elements_len += len(PADDING) if title != "" else 0
        # Title
        elements_len += len(title)
        # Separators
        elements_len += 2
        if RHS_STATUS_FILLED:
            # Title padding, if element has a title
            elements_len += len(PADDING) if title != "" else 0
    # Inter-tab soft separators
    elements_len += len(elements) - 1
    return elements_len


def _is_running_pager(active_window: Window) -> bool:
    try:
        return Path(active_window.child.argv[0]).name == "nvim-pager.py"
    except:
        return False


def _get_system_info(active_window: Window) -> Dict[str, Any]:
    # Local info (and fallback for errors on remote info)
    user = getpass.getuser()
    host = socket.gethostname()
    is_ssh = False

    ssh_cmdline = []
    # The propery "child_is_remote" is True when the command being executed is a
    # standard "ssh" command, without using the SSH kitten
    if active_window.child_is_remote:
        procs = sorted(active_window.child.foreground_processes, key=lambda p: p["pid"])
        for p in procs:
            if p["cmdline"][0] == "ssh":
                ssh_cmdline = p["cmdline"]
    # The command line is not an empty list in case we're running the ssh kitten
    else:
        ssh_cmdline = active_window.ssh_kitten_cmdline()

    if ssh_cmdline != []:
        is_ssh = True
        # Remove "-tt" argument from SSH cmdline, if present, because the function
        # get_connection_data() doesn't handle that properly
        ssh_cmdline = filter(lambda item: item != "-tt", ssh_cmdline)
        conn_data = get_connection_data(ssh_cmdline)
        if conn_data:
            conn_data_hostname = conn_data.hostname
            user_and_host = conn_data_hostname.split("@")
            # When only a host is specified on the command line, we try to lookup the
            # corresponding user in the SSH config file
            if len(user_and_host) == 1:
                host = user_and_host[0]
                config_fpath = str(Path(SSH_CONFIG_FILE).expanduser())
                host_config = SSHConfig.from_path(config_fpath).lookup(host)
                if "user" in host_config:
                    user = host_config["user"]
            # When the command line specifies both host and user, we just use these
            elif len(user_and_host) == 2:
                user, host = user_and_host
            else:
                print("Could not parse user and host name")
        else:
            print("Could not retrieve SSH connection data")

    return {"user": user, "host": host, "is_ssh": is_ssh}


def _get_git_info(active_window: Window, is_ssh: bool) -> Dict[str, Any]:
    # Git info currently only works in non-remote windows
    if is_ssh:
        return {"is_git_repo": False, "branch": ""}

    cwd = active_window.cwd_of_child
    proc = subprocess.run(
        ["git", "branch", "--show-current"], capture_output=True, cwd=cwd
    )

    # If the command fails we're probably not in a Git repo (note that often the command
    # does not error out, so checking the stderr protects against false negatives)
    if proc.returncode != 0 or len(proc.stderr) > 0:
        return {"is_git_repo": False, "branch": ""}

    branch = str(proc.stdout, "utf-8").strip() or "DETACHED"
    if len(branch) > MAX_BRANCH_LEN:
        start_len = (MAX_BRANCH_LEN - 1) // 2
        end_len = MAX_BRANCH_LEN - start_len - 1
        branch = branch[:start_len] + ELLIPSIS + branch[-end_len:]
        print(start_len, end_len, len(branch))

    return {"is_git_repo": True, "branch": branch}


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Draw tab.

    Args:
        draw_data (DrawData): Tab context.
        screen (Screen): Screen objects.
        tab (TabBarData): Tab bar context.
        before (int): Current cursor position, before drawing tab.
        max_tab_length (int): User-specified maximum length of tab.
        index (int): Tab index.
        is_last (bool): Whether this is the last tab to draw.
        extra_data (ExtraData): Additional context.

    Returns:
        int: Cursor positions after drawing current tab.
    """

    opts = get_options()
    colors = {}

    # Base foreground and background colors
    colors["fg"] = as_rgb(color_as_int(draw_data.inactive_fg))
    colors["bg"] = as_rgb(color_as_int(draw_data.default_bg))

    # Foreground, background and icon background colors for filled tabs
    colors["filled_fg"] = as_rgb(color_as_int(draw_data.active_fg))
    colors["filled_bg"] = as_rgb(color_as_int(draw_data.active_bg))
    colors["filled_icon_bg"] = as_rgb(color_as_int(FILLED_ICON_BG_COLOR))

    # Foreground, background and icon background colors for accented tabs
    colors["accented_fg"] = as_rgb(color_as_int(draw_data.active_fg))
    colors["accented_bg"] = as_rgb(color_as_int(ACCENTED_BG_COLOR))
    colors["accented_icon_bg"] = as_rgb(color_as_int(ACCENTED_ICON_BG_COLOR))

    # Inter-tab separator color
    colors["soft_sep_fg"] = as_rgb(color_as_int(SOFT_SEP_COLOR))

    soft_sep = None
    if DRAW_SOFT_SEP:
        if extra_data.next_tab:
            both_inactive = not tab.is_active and not extra_data.next_tab.is_active
            soft_sep = SOFT_SEP if both_inactive else PADDING

    # Draw main tabs
    end = _draw_element(
        draw_data,
        screen,
        tab,
        before,
        max_tab_length,
        index,
        colors,
        filled=tab.is_active,
        padded=PADDED_TABS,
        soft_sep=soft_sep,
    )

    # Draw right-hand side status
    if is_last:
        boss: Boss = get_boss()
        active_window = boss.active_window
        assert isinstance(active_window, Window)

        is_running_pager = _is_running_pager(active_window)
        sys_info = _get_system_info(active_window)
        user, host, is_ssh = sys_info["user"], sys_info["host"], sys_info["is_ssh"]
        git_info = _get_git_info(active_window, is_ssh)
        is_git_repo, branch = git_info["is_git_repo"], git_info["branch"]

        elements = list()
        if is_running_pager:
            elements.append({"title": "", "icon": PAGER_ICON, "accented": True})
        if is_git_repo:
            elements.append({"title": branch, "icon": BRANCH_ICON, "accented": False})
        elements.append({"title": user, "icon": USER_ICON, "accented": is_ssh})
        elements.append({"title": host, "icon": HOST_ICON, "accented": is_ssh})

        # Move cursor horizontally so that right-hand side status is right-aligned
        rhs_status_len = _calc_elements_len(elements)
        if opts.tab_bar_align == "center":
            screen.cursor.x = math.ceil(screen.columns / 2 + end / 2) - rhs_status_len
        else:  # opts.tab_bar_align == "left"
            screen.cursor.x = screen.columns - rhs_status_len

        for element in elements:
            _draw_element(
                element["title"],
                screen,
                tab,
                before,
                100,
                index,
                colors,
                filled=RHS_STATUS_FILLED,
                padded=False,
                accented=element["accented"],
                icon=element["icon"],
                soft_sep=PADDING if element is not elements[-1] else None,
            )

    return end
