;;; rust.el --- Rust development extras  -*- lexical-binding: t; -*-

;; Optional Rust layer for init.el. Disabled by default — uncomment the matching
;; loader at the bottom of init.el to enable it.
;;
;; Most of the stack is built in: the tree-sitter major mode (rust-ts-mode) and
;; eglot, which init.el already hooks onto prog-mode. You supply the external
;; tools:
;;   - rust-analyzer (rustup component add rust-analyzer) — eglot launches it
;;     automatically for completion / xref / refactors / formatting once it's
;;     on PATH
;;   - the CodeLLDB adapter (`codelldb') — driven here by dape for
;;     breakpoints/stepping
;;   - the tree-sitter grammar (M-x treesit-install-language-grammar RET rust) —
;;     until then .rs isn't auto-detected
;;
;; ELPA-only: dape is on GNU ELPA; the major mode and eglot are built in.
;; (rust-mode / rustic are MELPA-only, so they're not used here.) Cargo commands
;; run through M-x project-compile / compile.

;;; Built-in
;; rustfmt on save, via rust-analyzer (only fires when eglot is up).
(defun my/rust--format-on-save ()
  "Arrange for rust-analyzer to rustfmt the buffer before each save."
  (add-hook 'before-save-hook
            (lambda () (when (eglot-managed-p) (eglot-format-buffer)))
            nil t))

;; .rs → rust-ts-mode (Emacs doesn't bind it by default).
(use-package rust-ts-mode
  :ensure nil
  :init
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'rust))
    (add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode)))
  :hook (rust-ts-mode . my/rust--format-on-save)
  :custom
  (rust-ts-mode-indent-offset 4))
;;; End Built-in

;;; GNU ELPA
;; DAP-based debugging that pairs with eglot (no lsp-mode needed). To debug:
;; M-x dape, choose the `codelldb-rust' config (it uses the CodeLLDB adapter, so
;; codelldb must be installed). Set breakpoints with `dape-breakpoint-toggle';
;; n / c step once a session stops.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped
;;; End GNU ELPA

(provide 'rust)
;;; rust.el ends here
