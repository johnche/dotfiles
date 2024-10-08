;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "John Chen"
      user-mail-address "john20chen@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;;(setq doom-theme 'nil)
;;(setq doom-theme 'doom-solarized-light)

;; set `doom-theme'
(setq doom-everforest-background  "soft")  ; or hard (defaults to soft)
(setq doom-theme 'doom-everforest) ; dark variant
;;(setq doom-everforest-light-background  "soft") ; or hard (defaults to soft)
;;(setq doom-theme 'doom-everforest-light) ; light variant

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; (after! evil-escape (evil-escape-mode -1))
;; (after! evil-snipe (evil-snipe-mode -1))


;; https://github.com/doomemacs/doomemacs/issues/4178
(setq ns-right-alternate-modifier 'meta)

;; is this one necessary?
(setq lsp-rust-server 'rust-analyzer)

(setq org-roam-directory "~/Documents/org")

(setq deft-directory "~/Documents"
      deft-extensions '("org" "txt" "json")
      deft-recursive t)

(map!
 :desc "Next error" :n "] g g" #'flycheck-next-error
 :desc "Previous error" :n "[ g g" #'flycheck-previous-error
 :desc "Next workspace" :n "<right>" #'+workspace:switch-next
 :desc "Previous workspace" :n "<left>" #'+workspace:switch-previous
 :desc "Window left" :n "M-s-<left>" #'evil-window-left
 :desc "Window right" :n "M-s-<right>" #'evil-window-right
 :desc "Window up" :n "M-s-<up>" #'evil-window-up
 :desc "Window down" :n "M-s-<down>" #'evil-window-down
 )


;; Opening new buffers in split
;; https://discourse.doomemacs.org/t/open-selected-completion-candidate-in-a-split/2525/7
(defun custom/vsplit-file-open (f)
  (let ((evil-vsplit-window-right t))
    (+evil/window-vsplit-and-follow)
    (find-file f)))

(defun custom/split-file-open (f)
  (let ((evil-split-window-below t))
    (+evil/window-split-and-follow)
    (find-file f)))

;; "C-;"" to invoke embark
(map! :after embark
      :map embark-file-map
      "v" #'custom/vsplit-file-open
      "x" #'custom/split-file-open
      )

(after! dired
  (add-hook 'dired-mode-hook #'display-line-numbers-mode)
  )


(after! vterm
  (add-hook 'vterm-mode-hook (lambda nil (evil-emacs-state t)))
  )

(use-package! lsp
  :ensure
  :custom
  (lsp-rust-analyzer-server-display-inlay-hints t)
  )

(after! lsp-ui
  (setq lsp-ui-doc-enable t))

(after! dap-mode
  (setq dap-python-debugger 'debugpy))

(after! org
  (setq org-agenda-files '("~/Documents/org/agenda.org")))

;; (setq lsp-svelte-plugin-typescript-enable t)

;; (after! svelte-mode
;;   (add-hook 'svelte-mode-local-vars-hook #'lsp! 'append))

;; (use-package dired-subtree
;;   :ensure t
;;   :after dired
;;   :config
;;   (bind-key "<tab>" #'dired-subtree-toggle dired-mode-map)
;;   (bind-key "<backtab>" #'dired-subtree-cycle dired-mode-map)
;;   )
