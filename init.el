;;; init.el --- personal GNU Emacs 30 config  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Chubby Hippo
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
;; more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <https://www.gnu.org/licenses/>.
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 16 1024 1024))))

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
  (global-so-long-mode 1)
  (when (fboundp 'global-completion-preview-mode)
    (global-completion-preview-mode 1))
  (keymap-set key-translation-map "M-m" "C-c")
  (keymap-global-set "C-c f" #'find-file)
  (keymap-global-set "C-c k" #'kill-current-buffer)
  (keymap-global-set "C-c b m" #'bookmark-set)
  (keymap-global-set "C-z"   #'undo-only)
  (keymap-global-set "C-S-z" #'undo-redo)
  (windmove-default-keybindings)
  (winner-mode 1)
  (setq read-process-output-max (* 1024 1024))
  (setq custom-file (locate-user-emacs-file "custom.el"))
  (load custom-file 'noerror)
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)
  :custom
  (context-menu-mode t)
  (tab-always-indent 'complete)
  (enable-recursive-minibuffers t)
  (use-short-answers t)
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

(use-package bookmark
  :ensure nil
  :custom
  (bookmark-save-flag 1))

(defun my-eglot-ensure ()
  "Run `eglot-ensure', except in lisp modes with no language server."
  (unless (derived-mode-p 'lisp-data-mode)
    (eglot-ensure)))

(use-package eglot
  :ensure nil
  :hook (prog-mode . my-eglot-ensure)
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-config '(:size 0 :format full)))

(use-package flymake
  :ensure nil
  :commands (flymake-goto-next-error flymake-goto-prev-error)
  :preface
  (defun my-elisp-flymake ()
    "Flymake for elisp buffers: byte-compile diagnostics, no checkdoc."
    (remove-hook 'flymake-diagnostic-functions #'elisp-flymake-checkdoc t)
    (flymake-mode 1))
  :hook (emacs-lisp-mode . my-elisp-flymake)
  :custom
  (trusted-content (list (abbreviate-file-name (file-truename user-emacs-directory))))
  (flymake-show-diagnostics-at-end-of-line 'short)
  :config
  (defvar-keymap my-flymake-repeat-map
    :repeat t
    "." #'flymake-goto-next-error
    "," #'flymake-goto-prev-error)
  (put 'flymake-goto-next-error 'repeat-check-key 'no)
  (put 'flymake-goto-prev-error 'repeat-check-key 'no))

(use-package org
  :ensure nil
  :hook (org-mode . visual-line-mode)
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture)
         ("C-c l" . org-store-link))
  :custom
  (org-directory "~/org")
  (org-agenda-files (list org-directory))
  (org-startup-indented t)
  (org-return-follows-link t)
  (org-hide-emphasis-markers t)
  (org-catch-invisible-edits 'show-and-error))

;;; End Built-in

;;; GNU ELPA
(use-package avy
  :ensure t
  :custom
  (avy-timeout-seconds 0.25)
  :bind (("M-o"     . avy-goto-char-timer)
         ("M-g g"   . avy-goto-line)
         ("M-g M-g" . avy-goto-line)
         ("C-c j w" . avy-goto-char-2)
         ("C-c j l" . avy-goto-line)
         ("C-c j c" . avy-goto-char-timer)))

(use-package expreg
  :ensure t
  :bind (("M-r"   . expreg-expand)
         ("C-c e" . expreg-expand)
         ("M-R"   . expreg-contract))
  :config
  (defvar-keymap my-expreg-repeat-map
    :repeat t
    "." #'expreg-expand
    "," #'expreg-contract)
  (put 'expreg-expand   'repeat-check-key 'no)
  (put 'expreg-contract 'repeat-check-key 'no))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package vertico
  :ensure t
  :init
  (vertico-mode 1))

(use-package vertico-directory
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
         ("C-c b j" . consult-bookmark)
         ("C-c r" . consult-ripgrep)
         ("C-x b"   . consult-buffer)
         ("C-x C-b" . consult-buffer)
         ("C-x r b" . consult-bookmark)
         ("M-y"     . consult-yank-pop)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s s" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s o" . consult-outline)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi))
  :config
  (add-hook 'consult-after-jump-hook #'recenter)
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
  :ensure t
  :after (embark consult))

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
  (defun my-eglot-capfs ()
    "Merge eglot's capf with cape's while managed; restore the globals after."
    (if (eglot-managed-p)
        (setq-local completion-at-point-functions
                    (list (cape-capf-super #'eglot-completion-at-point
                                           #'cape-dabbrev)
                          #'cape-file
                          #'cape-keyword))
      (kill-local-variable 'completion-at-point-functions)))
  (add-hook 'eglot-managed-mode-hook #'my-eglot-capfs))

(use-package vundo
  :ensure t
  :bind ("C-x u" . vundo)
  :custom
  (vundo-glyph-alist vundo-unicode-symbols))

(use-package ace-window
  :ensure t
  :bind ([remap other-window] . ace-window)
  :custom
  (aw-scope 'frame)
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package diff-hl
  :ensure t
  :demand t
  :hook
  (dired-mode         . diff-hl-dired-mode)
  (magit-post-refresh . diff-hl-magit-post-refresh)
  :custom
  (diff-hl-update-async t)
  :config
  (keymap-set diff-hl-command-map "." #'diff-hl-next-hunk)
  (keymap-set diff-hl-command-map "," #'diff-hl-previous-hunk)
  (put 'diff-hl-next-hunk 'repeat-check-key 'no)
  (put 'diff-hl-previous-hunk 'repeat-check-key 'no)
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1)
  (unless (display-graphic-p)
    (diff-hl-margin-mode 1)))
;;; End GNU ELPA

;;; NonGNU ELPA
(use-package eat
  :ensure t
  :hook
  (eshell-load . eat-eshell-visual-command-mode)
  :config
  (with-eval-after-load 'meow
    (add-to-list 'meow-mode-state-list '(eat-mode . insert))))

(use-package corfu-terminal
  :ensure t
  :init
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))

(use-package wgrep
  :ensure t
  :custom
  (wgrep-auto-save-buffer t)
  :config
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
  (with-eval-after-load 'meow
    (dolist (mode '(magit-status-mode magit-log-mode magit-diff-mode
                    magit-revision-mode magit-stash-mode magit-process-mode))
      (add-to-list 'meow-mode-state-list (cons mode 'motion)))))

(use-package meow
  :ensure t
  :demand t
  :config
  (defun my-meow-setup ()
    "Meow's standard keybindings for a QWERTY keyboard."
    (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
    (meow-motion-overwrite-define-key
     '("j" . meow-next)
     '("k" . meow-prev)
     '("<escape>" . ignore))
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
     '("s"   . consult-line)
     '("b b" . consult-buffer)
     '(", c" . diff-hl-previous-hunk)
     '(", e" . flymake-goto-prev-error)
     '(". c" . diff-hl-next-hunk)
     '(". e" . flymake-goto-next-error))
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
  (my-meow-setup)
  (keymap-global-set "M-SPC" #'meow-keypad)
  (meow-global-mode 1))

;;; End NonGNU ELPA

;;; Window management
(defun my-text-scale-reset ()
  "Reset this buffer's text size back to the default."
  (interactive)
  (text-scale-set 0))

(defvar-keymap my-window-resize-map
  :doc "Resize the selected window; any other key exits."
  "l" #'enlarge-window-horizontally  "<right>" #'enlarge-window-horizontally
  "h" #'shrink-window-horizontally   "<left>"  #'shrink-window-horizontally
  "j" #'enlarge-window               "<down>"  #'enlarge-window
  "k" #'shrink-window                "<up>"    #'shrink-window)

(defun my-window-resize ()
  "Resize a window with h/l/j/k or the arrows; any other key exits.
With 3+ windows, pick which one with ace-window first.  With two windows the
divider is unambiguous, so resize the current window without moving focus;
ace-window would otherwise jump to the other window."
  (interactive)
  (require 'ace-window)
  (if (<= (length (window-list)) 2)
      (set-transient-map my-window-resize-map t nil "Resize %k")
    (aw-select " Ace - Resize"
               (lambda (win)
                 (aw-switch-to-window win)
                 (set-transient-map my-window-resize-map t nil "Resize %k")))))

(defvar-keymap my-window-map
  :doc "window commands"
  "v" #'split-window-right
  "s" #'split-window-below
  "d" #'delete-window
  "D" #'delete-other-windows
  "m" #'delete-other-windows
  "w" #'other-window
  "W" #'ace-swap-window
  "r" #'my-window-resize
  "h" #'windmove-left
  "j" #'windmove-down
  "k" #'windmove-up
  "l" #'windmove-right
  "H" #'windmove-swap-states-left
  "J" #'windmove-swap-states-down
  "K" #'windmove-swap-states-up
  "L" #'windmove-swap-states-right
  "b" #'balance-windows
  "," #'winner-undo
  "." #'winner-redo
  "u" #'my-text-scale-reset
  "i" #'text-scale-increase
  "o" #'text-scale-decrease
  "=" #'text-scale-increase
  "-" #'text-scale-decrease
  "0" #'my-text-scale-reset)
(keymap-set global-map "C-c w" my-window-map)

(defvar-keymap my-text-scale-repeat-map
  :repeat t
  "i" #'text-scale-increase
  "o" #'text-scale-decrease
  "u" #'my-text-scale-reset
  "=" #'text-scale-increase
  "-" #'text-scale-decrease
  "0" #'my-text-scale-reset)

(defvar-keymap my-winner-repeat-map
  :repeat t
  "," #'winner-undo
  "." #'winner-redo)

;;; Extras (optional, disabled by default)
;; (load (expand-file-name "extras/clojure.el"    user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/cpp.el"        user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/elixir.el"     user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/erlang.el"     user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/go.el"         user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/java.el"       user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/python.el"     user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/rust.el"       user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/scheme.el"     user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/typescript.el" user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/zig.el"        user-emacs-directory) :noerror :nomessage)
