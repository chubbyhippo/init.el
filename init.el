;; Lower the GC ceiling raised in early-init.el once startup is done.
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 16 1024 1024)))) ; 16 MB

;;; Built-in
(use-package emacs
  :config
  (load-theme 'modus-vivendi)
  (repeat-mode 1)
  ;; Leader bindings: kanata NUM-thumb hold sends C-c <key> (see kanata-settings)
  (keymap-global-set "C-c f" #'find-file)
  (keymap-global-set "C-c s" #'save-buffer)
  (keymap-global-set "C-c k" #'kill-current-buffer)
  (keymap-global-set "C-c b" #'consult-buffer)
  (keymap-global-set "C-c r" #'consult-ripgrep)
  (keymap-global-set "C-c l" #'consult-line)
  :custom
  (context-menu-mode t)
  (tab-always-indent 'complete)
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)))

(use-package pixel-scroll
  :ensure nil
  :init
  (pixel-scroll-precision-mode 1))

(use-package which-key
  :ensure nil
  :init
  (which-key-mode 1))

(use-package windmove
  :ensure nil
  :init
  (windmove-default-keybindings 'control))

(use-package autorevert
  :ensure nil
  :custom
  (auto-revert-avoid-polling t)
  (auto-revert-interval 5)
  (auto-revert-check-vc-info t)
  :init
  (global-auto-revert-mode 1))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1))

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
	 ("M-g g"   . avy-goto-line)   ; typing digits still = goto-line
	 ("M-g M-g" . avy-goto-line)))

(use-package expreg
  :ensure t
  :bind (
	 ("M-'" . expreg-expand))   ; M- works in emacs -nw (ESC prefix), C-' doesn't
  :config
  ;; contract only matters mid-sequence: M-' then ' = expand more, ; = contract
  ;; (needs repeat-mode, enabled in the emacs block at the top)
  (defvar-keymap expreg-repeat-map
    :repeat t
    "'" #'expreg-expand
    ";" #'expreg-contract))

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

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

(use-package consult
  :ensure t
  :bind (
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

;;; End NonGNU ELPA
