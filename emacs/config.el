;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "John Chen"
      user-mail-address "john20chen@gmail.com")



;; set `doom-theme'
;;(setq doom-theme 'nil)
(setq doom-theme 'doom-solarized-light)

;;(setq doom-everforest-background  "soft")
;;(setq doom-theme 'doom-everforest)

;;(setq doom-everforest-background  "hard")
;;(setq doom-theme 'doom-everforest-light)

(setq display-line-numbers-type 'visual)
(setq org-directory "~/Documents/org/")


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

;; for modularizing
;; (add-load-path! "<some path>")
;; (require 'filename)

;; https://github.com/doomemacs/doomemacs/issues/4178
(setq ns-right-alternate-modifier 'meta)

;; is this one necessary?
(setq lsp-rust-server 'rust-analyzer)

(setq deft-directory "~/Documents/org"
      deft-extensions '("org" "txt" "json")
      deft-recursive t)

(setq calendar-week-start-day 1)

(after! org-fancy-priorities
  (setq
   org-fancy-priorities-list '("[A]" "[B]" "[C]")
   org-priority-faces
   '((?A :foreground "#F85552" :weight bold)
     (?B :foreground "#DFA000" :weight bold)
     (?C :foreground "#8DA101" :weight bold)))
  )

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
  (add-hook 'vterm-mode-hook 'evil-emacs-state)
  )

(use-package! lsp
  :ensure
  :custom
  (setq lsp-rust-analyzer-server-display-inlay-hints t)
  )

(after! lsp-ui
  (setq lsp-ui-doc-enable t))

(after! dap-mode
  (setq dap-python-debugger 'debugpy))

(use-package! websocket
  :after org-roam)

(setq org-roam-directory "~/Documents/org/roam")

(use-package! org-roam-ui
  :after org-roam ;; or :after org
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))


(use-package! bicep-mode
  :load-path "~/.local/share/doom-plugged/bicep-mode")

(add-to-list 'load-path "~/.local/share/doom-plugged/lsp-biome")

;;;; ical -> doom emacs
;;(defun calendar-helper () ;; doesn't have to be interactive
;;  (cfw:open-calendar-buffer
;;   :contents-sources
;;   (list
;;    (cfw:org-create-source "Purple")
;;    (cfw:ical-create-source "Private" "~/emacs/calendar/john-shared.ics" "Green")
;;    (cfw:ical-create-source "Webstep" "~/emacs/calendar/john.chen@webstep.no.ics" "Blue"))))
;;(defun calendar-init ()
;;  ;; switch to existing calendar buffer if applicable
;;  (if-let (win (cl-find-if (lambda (b) (string-match-p "^\\*cfw:" (buffer-name b)))
;;                           (doom-visible-windows)
;;                           :key #'window-buffer))
;;      (select-window win)
;;    (calendar-helper)))
;;(defun =my-calendar ()
;;  "Activate (or switch to) *my* `calendar' in its workspace."
;;  (interactive)
;;  (if (featurep! :ui workspaces) ;; create workspace (if enabled)
;;      (progn
;;        (+workspace-switch "Calendar" t)
;;        (doom/switch-to-scratch-buffer)
;;        (calendar-init)
;;        (+workspace/display))
;;    (setq +calendar--wconf (current-window-configuration))
;;    (delete-other-windows)
;;    (switch-to-buffer (doom-fallback-buffer))
;;    (calendar-init)))

;;(after! apheleia-formatters
;;  (set-formatter! 'prettier
;;    '("apheleia-npx" "prettier" "--stdin-filepath" filepath)))

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
