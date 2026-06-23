;; startup's over, so drop the GC ceiling back down (early-init.el cranked it up)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 16 1024 1024)))) ; 16mb

;;; Built-in
(use-package emacs
  :config
  (load-theme 'modus-operandi)
  (repeat-mode 1)
  (which-key-mode 1)
  (pixel-scroll-precision-mode 1)
  (savehist-mode 1)
  (save-place-mode 1)
  (electric-pair-mode 1)
  (when (fboundp 'global-completion-preview-mode)
    (global-completion-preview-mode 1)) ; emacs 30 ghost text, happy alongside corfu
  (keymap-set key-translation-map "M-m" "C-c")
  (keymap-global-set "C-c f" #'find-file)
  (keymap-global-set "C-c s" #'save-buffer)
  (keymap-global-set "C-c k" #'kill-current-buffer)
  (keymap-global-set "C-z"   #'undo-only)
  (keymap-global-set "C-S-z" #'undo-redo)
  (windmove-default-keybindings)
  (winner-mode 1) ; C-c left/right undoes/redoes window layouts, goes with windmove
  :custom
  (context-menu-mode t)
  (tab-always-indent 'complete)
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)))

(use-package autorevert
  :ensure nil
  :custom
  (auto-revert-avoid-polling t)
  (auto-revert-interval 5)
  (auto-revert-check-vc-info t)
  :init
  (global-auto-revert-mode 1))

(use-package recentf
  :ensure nil
  :init 
  (recentf-mode 1)
  :custom 
  (recentf-max-saved-items 200))

(use-package eglot
  :ensure nil
  :hook (prog-mode . eglot-ensure)
  :custom
  (eglot-autoshutdown t))

(use-package org
  :ensure nil
  :hook (org-mode . visual-line-mode)         ; wrap long lines instead of chopping them off
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture)
         ("C-c l" . org-store-link))
  :custom
  (org-directory "~/org")
  (org-agenda-files (list org-directory))
  (org-startup-indented t)                    ; fake indent under headlines (this is what turns on org-indent-mode)
  (org-return-follows-link t)                 ; RET follows the link under point
  (org-hide-emphasis-markers t)               ; hide the *bold* and =code= markers
  (org-catch-invisible-edits 'show-and-error)) ; warn me before I edit inside folded text

;;; End Built-in

;;; GNU ELPA
(use-package avy
  :ensure t
  :custom
  (avy-timeout-seconds 0.25)
  :bind (
	 ("M-o"     . avy-goto-char-timer)
	 ("M-g g"   . avy-goto-line)
	 ("M-g M-g" . avy-goto-line)
	 ("C-c j w" . avy-goto-char-2)
	 ("C-c j l" . avy-goto-line)
	 ("C-c j c" . avy-goto-char-timer)))

(use-package expreg
  :ensure t
  :bind (
	 ("M-r" . expreg-expand)      ; M- still reachable in the terminal via the ESC prefix
	 ("M-R" . expreg-contract)))  ; M-S-r shrinks a step; mash M-r to grow again

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t))

(use-package vertico
  :ensure t
  :init
  (vertico-mode 1))

(use-package vertico-directory ;; bundled with vertico
  :ensure nil
  :after vertico
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ("DEL"   . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word)))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

(use-package consult
  :ensure t
  :bind (
         ("C-c b" . consult-buffer)
         ("C-c r" . consult-ripgrep)
         ;; replacements for the stock bindings
         ("C-x b"   . consult-buffer)
         ("C-x C-b" . consult-buffer)   ; ditch the clunky buffer list for the good switcher
         ("M-y"     . consult-yank-pop)
         ;; search
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s s" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s o" . consult-outline)
         ;; isearch
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi))
  :config
  ;; recenter after a consult jump, otherwise the hit lands at the screen edge
  (add-hook 'consult-after-jump-hook #'recenter)
  ;; type < then a key to narrow results down to one group
  (setq consult-narrow-key "<")
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)
  (advice-add #'register-preview :override #'consult-register-window))

(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)
   ("M-." . embark-dwim)
   ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :ensure t)

(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-popupinfo-delay '(0.5 . 0.1))
  :init
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1)
  (corfu-history-mode 1)
  :config
  (add-to-list 'savehist-additional-variables 'corfu-history)
  :bind
  (:map corfu-map
        ("SPC" . corfu-insert-separator)
        ("C-n" . corfu-next)
        ("C-p" . corfu-previous)))

(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-keyword)
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (setq-local completion-at-point-functions
                          (list (cape-capf-super #'eglot-completion-at-point
                                                 #'cape-dabbrev)
                                #'cape-file
                                #'cape-keyword)))))

(use-package vundo
  :ensure t
  :bind ("C-x u" . vundo)
  :custom
  (vundo-glyph-alist vundo-unicode-symbols))

(use-package ace-window
  :ensure t
  :bind ([remap other-window] . ace-window)   ; label each window, jump by key (also powers C-c w w)
  :custom
  (aw-scope 'frame)
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))
;;; End GNU ELPA

;;; NonGNU ELPA
(use-package eat
  :ensure t
  :hook
  (eshell-load . eat-eshell-mode)
  (eshell-load . eat-eshell-visual-command-mode)
  :config
  ;; visual commands in eshell (less, htop, top...) get their own eat-mode
  ;; terminal. shove it into meow INSERT so every key passes straight through,
  ;; otherwise meow assumes MOTION and grabs the SPC/j/k a pager needs to page
  ;; and scroll. ESC still drops you to NORMAL, but you quit these with q.
  (with-eval-after-load 'meow
    (add-to-list 'meow-mode-state-list '(eat-mode . insert))))

(use-package corfu-terminal ;; gives corfu popups in the terminal (emacs 30 can't do tty child frames)
  :ensure t
  :init
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))

(use-package wgrep ;; consult-ripgrep, embark-export, then C-c C-p to edit the matches in place
  :ensure t
  :custom
  (wgrep-auto-save-buffer t)
  :config
  ;; grep buffers are read-only so meow parks them in MOTION. C-c C-p makes them
  ;; editable but only swaps the local keymap (still grep-mode underneath), so
  ;; meow-mode-state-list never catches it. jump to NORMAL on edit (you need i to
  ;; type, and MOTION would eat SPC/j/k mid-edit) and back to MOTION when you're
  ;; done or bail out. same trick meow uses for its own `occur-edit-mode' . normal.
  (with-eval-after-load 'meow
    (advice-add 'wgrep-change-to-wgrep-mode :after
                (lambda (&rest _) (meow--switch-state 'normal)))
    (advice-add 'wgrep-to-original-mode :after
                (lambda (&rest _) (meow--switch-state 'motion)))))

(use-package magit
  :ensure t
  :bind (("C-x g"   . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c M-g" . magit-file-dispatch))
  :config
  ;; keep magit's read-only buffers in MOTION; NORMAL would stomp on its
  ;; single-key commands (s stage, c commit, p push, f fetch, l log, d diff).
  (with-eval-after-load 'meow
    (dolist (mode '(magit-status-mode magit-log-mode magit-diff-mode
                    magit-revision-mode magit-stash-mode magit-process-mode))
      (add-to-list 'meow-mode-state-list (cons mode 'motion)))))

;; meow is vim-flavored modal editing. mostly two states:
;;   NORMAL: keys run commands (move, select, edit). you start here.
;;   INSERT: keys type text. i or a to get in, ESC to get out.
;; hit SPC in NORMAL to pop the leader (the command menu).
(use-package meow
  :ensure t
  :demand t
  :config
  (defun my/meow-setup ()
    "Meow's standard keybindings for a QWERTY keyboard."
    (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
    ;; MOTION: for read-only buffers. j/k move, ESC does nothing.
    (meow-motion-overwrite-define-key
     '("j" . meow-next)
     '("k" . meow-prev)
     '("<escape>" . ignore))
    ;; leader (SPC): 0-9 give a count, / explains a key, ? brings up the cheatsheet.
    (meow-leader-define-key
     '("1" . meow-digit-argument)
     '("2" . meow-digit-argument)
     '("3" . meow-digit-argument)
     '("4" . meow-digit-argument)
     '("5" . meow-digit-argument)
     '("6" . meow-digit-argument)
     '("7" . meow-digit-argument)
     '("8" . meow-digit-argument)
     '("9" . meow-digit-argument)
     '("0" . meow-digit-argument)
     '("/" . meow-keypad-describe-key)
     '("?" . meow-cheatsheet)
     ;; consult shortcuts, spelled out so keypad translation doesn't drop them
     '("b"   . consult-buffer)
     '("s"   . consult-line)
     '("x b" . consult-buffer))
    ;; NORMAL: every key edits (i/a when you actually want to type).
    (meow-normal-define-key
     '("0" . meow-expand-0)
     '("9" . meow-expand-9)
     '("8" . meow-expand-8)
     '("7" . meow-expand-7)
     '("6" . meow-expand-6)
     '("5" . meow-expand-5)
     '("4" . meow-expand-4)
     '("3" . meow-expand-3)
     '("2" . meow-expand-2)
     '("1" . meow-expand-1)
     '("-" . negative-argument)
     '(";" . meow-reverse)
     '("," . meow-inner-of-thing)
     '("." . meow-bounds-of-thing)
     '("[" . meow-beginning-of-thing)
     '("]" . meow-end-of-thing)
     '("<" . meow-beginning-of-thing)
     '(">" . meow-end-of-thing)
     '("a" . meow-append)
     '("A" . meow-open-below)
     '("b" . meow-back-word)
     '("B" . meow-back-symbol)
     '("c" . meow-change)
     '("d" . meow-delete)
     '("D" . meow-backward-delete)
     '("e" . meow-next-word)
     '("E" . meow-next-symbol)
     '("f" . meow-find)
     '("g" . meow-cancel-selection)
     '("G" . meow-grab)
     '("h" . meow-left)
     '("H" . meow-left-expand)
     '("i" . meow-insert)
     '("I" . meow-open-above)
     '("j" . meow-next)
     '("J" . meow-next-expand)
     '("k" . meow-prev)
     '("K" . meow-prev-expand)
     '("l" . meow-right)
     '("L" . meow-right-expand)
     '("m" . meow-join)
     '("n" . meow-search)
     '("o" . meow-block)
     '("O" . meow-to-block)
     '("p" . meow-yank)
     '("q" . meow-quit)
     '("Q" . avy-goto-line)
     '("r" . meow-replace)
     '("R" . meow-swap-grab)
     '("s" . meow-kill)
     '("S" . avy-goto-char-timer)
     '("t" . meow-till)
     '("u" . meow-undo)
     '("U" . meow-undo-in-selection)
     '("v" . meow-visit)
     '("w" . meow-mark-word)
     '("W" . meow-mark-symbol)
     '("x" . meow-line)
     '("X" . meow-goto-line)
     '("y" . meow-save)
     '("Y" . meow-sync-grab)
     '("z" . meow-pop-selection)
     '("'" . repeat)
     '("<escape>" . ignore)))
  (my/meow-setup)
  ;; M-SPC reaches the leader even from INSERT
  (keymap-global-set "M-SPC" #'meow-keypad)
  (meow-global-mode 1))

;;; End NonGNU ELPA

;;; Window management
;; mnemonic submenu on C-c w (meow: SPC w), which-key spells out the whole menu
(defun my/text-scale-reset ()
  "Reset this buffer's text size back to the default."
  (interactive)
  (text-scale-set 0))

(defvar-keymap my/window-map
  :doc "window commands"
  "v" #'split-window-right        ; two side by side
  "s" #'split-window-below        ; one stacked on the other
  "d" #'delete-window             ; close this window  (old C-x 0)
  "m" #'delete-other-windows      ; maximize this one  (old C-x 1)
  "w" #'other-window              ; ace-window remaps this once it's loaded (SPC w w)
  "h" #'windmove-left
  "j" #'windmove-down
  "k" #'windmove-up
  "l" #'windmove-right
  "b" #'balance-windows
  "u" #'winner-undo
  "r" #'winner-redo
  "=" #'text-scale-increase       ; zoom in
  "-" #'text-scale-decrease       ; zoom out
  "0" #'my/text-scale-reset)      ; reset zoom
(keymap-set global-map "C-c w" my/window-map)

;; repeat-mode is on, so after the first zoom just keep tapping =/-/0
(defvar-keymap my/text-scale-repeat-map
  :repeat t
  "=" #'text-scale-increase
  "-" #'text-scale-decrease
  "0" #'my/text-scale-reset)
