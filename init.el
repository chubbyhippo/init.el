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
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)
            (when (boundp 'my--file-name-handler-alist)
              (setq file-name-handler-alist my--file-name-handler-alist))))

;;; Built-in
(require 'winner)
(require 'savehist)

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
  ;; Keep backups, autosaves, and lockfiles out of project trees.
  (let ((backup-dir (expand-file-name "var/backup/" user-emacs-directory))
        (auto-save-dir (expand-file-name "var/auto-save/" user-emacs-directory))
        (lock-dir (expand-file-name "var/lock/" user-emacs-directory)))
    (dolist (dir (list backup-dir auto-save-dir lock-dir))
      (unless (file-directory-p dir)
        (make-directory dir t)))
    (setq backup-directory-alist `(("." . ,backup-dir))
          auto-save-file-name-transforms `((".*" ,auto-save-dir t))
          auto-save-list-file-prefix (expand-file-name ".saves-" auto-save-dir)
          lock-file-name-transforms `((".*" ,lock-dir t))))
  :custom
  (visible-bell t)
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

(use-package project
  :ensure nil
  :custom
  (project-vc-extra-root-markers
   '("package.json" "tsconfig.json" "jsconfig.json" "deno.json" "deno.jsonc" "bunfig.toml"
     "pyproject.toml" "setup.py" "setup.cfg" "requirements.txt" "Pipfile"
     "Cargo.toml"
     "go.mod" "go.work"
     "pom.xml" "build.gradle" "build.gradle.kts" "settings.gradle" "settings.gradle.kts" "gradlew" "mvnw"
     "deps.edn" "project.clj" "shadow-cljs.edn" "build.boot"
     "CMakeLists.txt" "compile_commands.json" "meson.build"
     "mix.exs"
     "rebar.config" "erlang.mk"
     "cabal.project" "stack.yaml" "package.yaml" "*.cabal"
     "Gemfile" "Rakefile" "*.gemspec"
     "build.zig" "build.zig.zon"
     "superbol.toml"
     "cpanfile" "Makefile.PL" "Build.PL" "dist.ini"
     "guix.scm" "manifest.scm" "akku.manifest")))

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
  :config
  (set-face-attribute 'avy-lead-face nil :background "#2ECC71" :foreground "#ffffff")
  (set-face-attribute 'avy-lead-face-0 nil :background "#2ECC71" :foreground "#ffffff")
  :bind (("M-o"     . avy-goto-char-timer)
         ("M-g g"   . avy-goto-line)
         ("M-g M-g" . avy-goto-line)
         ("C-c j w" . avy-goto-char-2)
         ("C-c j l" . avy-goto-line)
         ("C-c j c" . avy-goto-char-timer)))

(use-package expreg
  :ensure t
  :bind (("M-r"     . expreg-expand)
         ("C-c e e" . expreg-expand)
         ("M-R"     . expreg-contract))
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
  :preface
  (declare-function vertico-mode "vertico")
  :config
  (vertico-mode 1))

(defvar vertico-map)
(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
              ("RET"   . vertico-directory-enter)
              ("DEL"   . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word)))

(use-package marginalia
  :ensure t
  :preface
  (declare-function marginalia-mode "marginalia")
  :config
  (marginalia-mode 1))

(use-package consult
  :ensure t
  :preface
  (defvar consult-narrow-key)
  (declare-function consult-xref "consult")
  (declare-function consult-register-window "consult")
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
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  (setq register-preview-delay 0.5)
  (advice-add #'register-preview :override #'consult-register-window)
  :config
  (setq consult-narrow-key "<"))

(use-package embark
  :ensure t
  :preface
  (declare-function embark-prefix-help-command "embark")
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

(defvar corfu-map)
(use-package corfu
  :ensure t
  :preface
  (declare-function global-corfu-mode "corfu")
  (declare-function corfu-popupinfo-mode "corfu-popupinfo")
  (declare-function corfu-history-mode "corfu-history")
  (declare-function corfu-insert-separator "corfu")
  (declare-function corfu-next "corfu")
  (declare-function corfu-previous "corfu")
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-popupinfo-delay '(0.5 . 0.1))
  :config
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1)
  (corfu-history-mode 1)
  (add-to-list 'savehist-additional-variables 'corfu-history)
  :bind
  (:map corfu-map
        ("SPC" . corfu-insert-separator)
        ("C-n" . corfu-next)
        ("C-p" . corfu-previous)))

(use-package cape
  :ensure t
  :preface
  (declare-function eglot-completion-at-point "eglot")
  (declare-function eglot-managed-p "eglot")
  (declare-function cape-capf-super "cape")
  (declare-function cape-dabbrev "cape")
  (declare-function cape-file "cape")
  (declare-function cape-keyword "cape")
  (defun my-eglot-capf ()
    "Eglot's completions merged with dabbrev's, as a single capf."
    (funcall (cape-capf-super #'eglot-completion-at-point #'cape-dabbrev)))
  (defun my-eglot-capfs ()
    "Add `my-eglot-capf' to this buffer while eglot manages it, remove it after.
`eglot-managed-mode-hook' fires on disable too, so this adds and removes only
its own capf: replacing the buffer-local list and killing it on the way out
would take the major mode's own capf with it."
    (if (eglot-managed-p)
        (add-hook 'completion-at-point-functions #'my-eglot-capf -10 t)
      (remove-hook 'completion-at-point-functions #'my-eglot-capf t)))
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-keyword)
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
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :config
  (set-face-attribute 'aw-leading-char-face nil
                      :background 'unspecified :foreground "#2ECC71" :weight 'bold))

(defvar diff-hl-command-map)
(use-package diff-hl
  :ensure t
  :demand t
  :preface
  (declare-function diff-hl-next-hunk "diff-hl")
  (declare-function diff-hl-previous-hunk "diff-hl")
  (declare-function diff-hl-margin-mode "diff-hl-margin")
  (declare-function diff-hl-dired-mode "diff-hl-dired")
  (declare-function diff-hl-magit-post-refresh "diff-hl")
  (declare-function global-diff-hl-mode "diff-hl")
  (declare-function diff-hl-flydiff-mode "diff-hl-flydiff")
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
(defvar meow-mode-state-list)
(declare-function meow--switch-state "meow")

(use-package eat
  :ensure t
  :hook
  (eshell-load . eat-eshell-visual-command-mode)
  :config
  (with-eval-after-load 'meow
    (add-to-list 'meow-mode-state-list '(eat-mode . insert))))

(use-package corfu-terminal
  :ensure t
  :defer t
  :preface
  (declare-function corfu-terminal-mode "corfu-terminal")
  :init
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))

(use-package wgrep
  :ensure t
  :commands (wgrep-change-to-wgrep-mode)
  :custom
  (wgrep-auto-save-buffer t)
  :config
  (with-eval-after-load 'meow
    (advice-add 'wgrep-change-to-wgrep-mode :after
                (lambda (&rest _) (meow--switch-state 'normal))
                '((name . my-wgrep--enter-normal)))
    (advice-add 'wgrep-to-original-mode :after
                (lambda (&rest _) (meow--switch-state 'motion))
                '((name . my-wgrep--restore-motion)))))

(use-package magit
  :ensure t
  :bind (("C-x g"   . magit-status)
         ("C-x M-g" . magit-dispatch)
         ("C-c M-g" . magit-file-dispatch))
  :custom
  (magit-status-show-untracked-files (not (eq system-type 'windows-nt)))
  (magit-diff-paint-whitespace (not (eq system-type 'windows-nt)))
  (magit-auto-revert-immediately (not (eq system-type 'windows-nt)))
  :config
  (with-eval-after-load 'meow
    (dolist (mode '(magit-status-mode magit-log-mode magit-diff-mode
                    magit-revision-mode magit-stash-mode magit-process-mode))
      (add-to-list 'meow-mode-state-list (cons mode 'motion)))))

(use-package meow
  :ensure t
  :demand t
  :preface
  (defvar meow-cheatsheet-layout-qwerty)
  (defvar meow-cheatsheet-layout)
  (declare-function meow-motion-overwrite-define-key "meow")
  (declare-function meow-leader-define-key "meow")
  (declare-function meow-normal-define-key "meow")
  (declare-function meow-keypad "meow")
  (declare-function meow-global-mode "meow")
  (declare-function meow-thing-register "meow")
  (defvar meow-char-thing-table)
  (defvar sgml-mode-syntax-table)
  (declare-function sgml-get-context "sgml-mode")
  (declare-function sgml-tag-type "sgml-mode")
  (declare-function sgml-tag-start "sgml-mode")
  (declare-function sgml-tag-end "sgml-mode")
  (declare-function sgml-skip-tag-backward "sgml-mode")
  (declare-function sgml-skip-tag-forward "sgml-mode")

  (defun my-meow-bounds-of-tag ()
    "Return the bounds (START . END) of the surrounding HTML/XML tag."
    (save-excursion
      (require 'sgml-mode)
      (with-syntax-table sgml-mode-syntax-table
        (when (and (looking-at-p "<[^/]") (not (looking-back ">" 1)))
          (forward-char 1))
        (let ((context (sgml-get-context)))
          (when context
            (let ((tag (car (last context))))
              (condition-case nil
                  (if (eq (sgml-tag-type tag) 'close)
                      (progn
                        (goto-char (sgml-tag-end tag))
                        (sgml-skip-tag-backward 1)
                        (let ((beg (point)))
                          (sgml-skip-tag-forward 1)
                          (cons beg (point))))
                    (let ((beg (sgml-tag-start tag)))
                      (goto-char beg)
                      (sgml-skip-tag-forward 1)
                      (cons beg (point))))
                (error nil))))))))

  (defun my-meow-inner-of-tag ()
    "Return the inner bounds (START . END) between opening > and closing <."
    (when-let* ((bounds (my-meow-bounds-of-tag)))
      (save-excursion
        (let (beg end)
          (goto-char (car bounds))
          (if (re-search-forward ">" (cdr bounds) t)
              (setq beg (point))
            (setq beg (car bounds)))
          (goto-char (cdr bounds))
          (if (re-search-backward "<" beg t)
              (setq end (point))
            (setq end (cdr bounds)))
          (cons beg end)))))

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
     '("r"   . consult-ripgrep)
     '("b b" . consult-buffer)
     '("e e" . expreg-expand)
     '("p f" . project-find-file)
     '("p p" . project-switch-project)
     '("o a" . org-agenda)
     '("o c" . org-capture)
     '("o l" . org-store-link)
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
  :config
  (set-face-attribute 'secondary-selection nil :background "#C0F0CD")
  (my-meow-setup)
  (meow-thing-register 'tag #'my-meow-inner-of-tag #'my-meow-bounds-of-tag)
  (add-to-list 'meow-char-thing-table '(?t . tag))
  (add-to-list 'meow-char-thing-table '(?\( . round))
  (add-to-list 'meow-char-thing-table '(?\) . round))
  (add-to-list 'meow-char-thing-table '(?\[ . square))
  (add-to-list 'meow-char-thing-table '(?\] . square))
  (add-to-list 'meow-char-thing-table '(?{ . curly))
  (add-to-list 'meow-char-thing-table '(?} . curly))
  (add-to-list 'meow-char-thing-table '(?\' . string))
  (add-to-list 'meow-char-thing-table '(?\" . string))
  (meow-thing-register 'angle
                       '(pair ("<") (">"))
                       '(pair ("<") (">")))
  (add-to-list 'meow-char-thing-table '(?a . angle))
  (add-to-list 'meow-char-thing-table '(?< . angle))
  (add-to-list 'meow-char-thing-table '(?> . angle))
  (meow-thing-register 'slash
                       '(regexp "/" "/")
                       '(regexp "/" "/"))
  (add-to-list 'meow-char-thing-table '(?/ . slash))
  (meow-thing-register 'question
                       '(regexp "\\?" "\\?")
                       '(regexp "\\?" "\\?"))
  (add-to-list 'meow-char-thing-table '(?\? . question))
  (keymap-global-set "M-SPC" #'meow-keypad)
  (meow-global-mode 1))

;;; End NonGNU ELPA

;;; Window management
(declare-function aw-select "ace-window")
(declare-function aw-switch-to-window "ace-window")
(declare-function ace-swap-window "ace-window")

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

;;; Config editing
(defun my-edit-init-file ()
  "Open this config's init.el for editing."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

(defun my-reload-init-file ()
  "Reload this config's init.el."
  (interactive)
  (load-file (expand-file-name "init.el" user-emacs-directory)))

(keymap-global-set "C-c e m" #'my-edit-init-file)
(keymap-global-set "C-c e M" #'my-reload-init-file)

;;; Extras (optional, disabled by default)
;; (load (expand-file-name "extras/clojure.el"    user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/cobol.el"      user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/cpp.el"        user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/elixir.el"     user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/erlang.el"     user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/go.el"         user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/haskell.el"    user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/html.el"       user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/java.el"       user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/perl.el"       user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/python.el"     user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/ruby.el"       user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/rust.el"       user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/scheme.el"     user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/typescript.el" user-emacs-directory) :noerror :nomessage)
;; (load (expand-file-name "extras/zig.el"        user-emacs-directory) :noerror :nomessage)
