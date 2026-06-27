;;; go.el --- Go development extras  -*- lexical-binding: t; -*-

;; Optional Go layer for init.el. Disabled by default — uncomment the matching
;; loader at the bottom of init.el to enable it.
;;
;; Most of the stack is built in: the tree-sitter major modes (go-ts-mode,
;; go-mod-ts-mode) and eglot, which init.el already hooks onto prog-mode. You
;; supply the external tools:
;;   - gopls (go install golang.org/x/tools/gopls@latest) — eglot launches it
;;     automatically for completion / xref / refactors / formatting once it's
;;     on PATH
;;   - Delve (go install github.com/go-delve/delve/cmd/dlv@latest) — driven here
;;     by dape for breakpoints/stepping
;;   - the tree-sitter grammars (M-x treesit-install-language-grammar RET go,
;;     then again for gomod) — until then .go / go.mod aren't auto-detected
;;
;; ELPA-only: dape is on GNU ELPA; the major modes and eglot are built in.
;; (go-mode is MELPA-only, so it's not used here.)

;;; Built-in
;; gofmt + organize-imports on save, via gopls (only fires when eglot is up).
(defun my/go--format-on-save ()
  "Arrange for gopls to gofmt and organize imports before each save."
  (add-hook 'before-save-hook
            (lambda ()
              (when (eglot-managed-p)
                (ignore-errors
                  (eglot-code-action-organize-imports (point-min) (point-max)))
                (eglot-format-buffer)))
            nil t))

;; .go → go-ts-mode, go.mod → go-mod-ts-mode (Emacs binds neither by default).
(use-package go-ts-mode
  :ensure nil
  :init
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'go))
    (add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode)))
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'gomod))
    (add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode)))
  :hook (go-ts-mode . my/go--format-on-save)
  :custom
  (go-ts-mode-indent-offset 4))
;;; End Built-in

;;; GNU ELPA
;; DAP-based debugging that pairs with eglot (no lsp-mode needed). To debug:
;; M-x dape, choose the `dlv' config (it runs `dlv dap', so Delve must be
;; installed). Set breakpoints with `dape-breakpoint-toggle'; n / c step.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped
;;; End GNU ELPA

;; No `(provide 'go)' — `go' is a short, generic feature name; this file is
;; loaded by path from init.el, so a provide isn't needed.
;;; go.el ends here
