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
  (windmove-default-keybindings 'shift))

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

(use-package avy
  :ensure t
  :demand t
  :bind (
	 ("C-;" . avy-goto-char-timer)
	 ("C-:" . avy-goto-line)))

(use-package expreg
  :ensure t
  :demand t
  :bind (
	 ("C-'" . expreg-expand)
	 ("C-\"" . expreg-contract)))

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

(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  :init
  (global-corfu-mode 1)
  :bind
  (:map corfu-map
        ("SPC" . corfu-insert-separator)
        ("C-n" . corfu-next)
        ("C-p" . corfu-previous)))

(use-package emacs
  :config
  (load-theme 'modus-vivendi)
  :custom
  (context-menu-mode t)
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)))
