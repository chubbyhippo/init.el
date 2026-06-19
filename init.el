;; Lower the GC ceiling raised in early-init.el once startup is done.
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 16 1024 1024)))) ; 16 MB

;;; Built-in
(use-package emacs
  :config
  (load-theme 'modus-vivendi)
  (repeat-mode 1)
  (which-key-mode 1)
  (pixel-scroll-precision-mode 1)
  (savehist-mode 1)
  (save-place-mode 1)
  (cua-mode 1)              ; C-c/C-x/C-v copy/cut/paste (region-aware); includes delete-selection-mode
  (electric-pair-mode 1)
  (when (fboundp 'global-completion-preview-mode)
    (global-completion-preview-mode 1)) ; Emacs 30 ghost-text suggestion; coexists with corfu
  (keymap-set key-translation-map "M-m" "C-c")
  (keymap-global-set "C-c f" #'find-file)
  (keymap-global-set "C-c s" #'save-buffer)
  (keymap-global-set "C-c k" #'kill-current-buffer)
  (keymap-global-set "C-z"   #'undo-only)
  (keymap-global-set "C-S-z" #'undo-redo)
  ;; These C-c keys double as leader shortcuts: SPC f, SPC s, SPC k (see Meow below).
  (windmove-default-keybindings)
  (winner-mode 1) ; C-c <left>/<right> = undo/redo window layout — pairs with windmove
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

;;; End Built-in

;;; GNU ELPA
(use-package avy
  :ensure t
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
	 ("M-r" . expreg-expand)      ; base-layer key; M- still works in emacs -nw (ESC prefix)
	 ("M-R" . expreg-contract)))  ; M-S-r contracts one step (re-press M-r to expand more)

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

(use-package vertico-directory ;; ships inside the vertico package
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
         ("C-c l" . consult-line)
         ;; Drop-in replacements
         ("C-x b" . consult-buffer)
         ("M-y"   . consult-yank-pop)
         ;; Searching
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s s" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s o" . consult-outline)
         ;; Isearch integration
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)
         ("M-s e" . consult-isearch-history)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi))
  :config
  ;; Narrowing lets you restrict results to certain groups of candidates
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
  :bind
  (:map corfu-map
        ("SPC" . corfu-insert-separator)
        ("C-n" . corfu-next)
        ("C-p" . corfu-previous)))

(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

(use-package vundo
  :ensure t
  :bind ("C-x u" . vundo)
  :custom
  (vundo-glyph-alist vundo-unicode-symbols))
;;; End GNU ELPA

;;; NonGNU ELPA
(use-package multiple-cursors
  :ensure t
  :bind
  (("C-S-c C-S-c" . mc/edit-lines)
   ("C->" . mc/mark-next-like-this)
   ("C-<" . mc/mark-previous-like-this)
   ("C-M->" . mc/skip-to-next-like-this)
   ("C-M-<" . mc/skip-to-previous-like-this)
   ("C-c C-<" . mc/mark-all-like-this)))

(use-package corfu-terminal ;; corfu popups in emacs -nw (Emacs 30 has no tty child frames)
  :ensure t
  :init
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))

(use-package wgrep ;; consult-ripgrep → embark-export → C-c C-p → edit matches in place
  :ensure t
  :custom
  (wgrep-auto-save-buffer t))

;; Meow brings Vim-style modal editing. You're always in one of two main states:
;;   NORMAL — keys run commands (move, select, edit); you start here.
;;   INSERT — keys type text; enter with i or a, leave with ESC.
;; Press SPC in NORMAL state to open the leader (your command menu).
(use-package meow
  :ensure t
  :demand t
  :config
  (defun my/meow-setup ()
    "Meow's standard keybindings for a QWERTY keyboard."
    (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
    ;; MOTION state: used in read-only buffers — j/k move, ESC does nothing.
    (meow-motion-overwrite-define-key
     '("j" . meow-next)
     '("k" . meow-prev)
     '("<escape>" . ignore))
    ;; Leader (SPC) keys: 0-9 repeat a command, / explains a key, ? shows the cheatsheet.
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
     '("?" . meow-cheatsheet))
    ;; NORMAL state: every key is an editing command (i/a to start typing).
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
  ;; M-SPC opens the leader even while typing (INSERT state).
  (keymap-global-set "M-SPC" #'meow-keypad)
  (meow-global-mode 1))

;;; End NonGNU ELPA
