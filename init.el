(pixel-scroll-precision-mode 1)
(which-key-mode 1)
(windmove-default-keybindings 'shift)

(setopt auto-revert-avoid-polling t)
(setopt auto-revert-interval 5)
(setopt auto-revert-check-vc-info t)
(global-auto-revert-mode 1)

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
