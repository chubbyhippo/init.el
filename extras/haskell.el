;;; haskell.el --- Haskell development extras  -*- lexical-binding: t; -*-

;; Optional Haskell layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it.
;;
;; The major mode is haskell-mode (NonGNU ELPA — the mature standard, with GHCi
;; REPL integration). eglot and dape are both built in and already know Haskell,
;; so you only supply the external tools:
;;   - haskell-language-server (HLS) — eglot's built-in entry launches it
;;     (haskell-language-server-wrapper --lsp) for completion / xref / refactors
;;     / formatting once it's on PATH
;;   - hdb, the Haskell debug adapter — dape's built-in `hdb' config uses it
;;
;; ELPA-only: haskell-mode is on NonGNU ELPA, dape on GNU ELPA; eglot is built
;; in. (haskell-ts-mode is also on NonGNU ELPA if you prefer tree-sitter, but
;; eglot's built-in server entry is keyed on haskell-mode, so that's what this
;; file uses.)

;;; NonGNU ELPA
;; haskell-mode auto-binds .hs / .lhs / … and derives from prog-mode, so eglot
;; attaches via init.el's prog-mode hook (HLS through eglot's built-in entry).
;; interactive-haskell-mode adds the GHCi REPL workflow (C-c C-l to load, etc.).
(use-package haskell-mode
  :ensure t
  :hook (haskell-mode . interactive-haskell-mode))
;;; End NonGNU ELPA

;;; GNU ELPA
;; DAP-based debugging that pairs with eglot. dape ships a built-in Haskell
;; config, so just M-x dape → `hdb' (it runs the hdb debug adapter, which must
;; be on PATH). Set breakpoints with `dape-breakpoint-toggle'; n / c step.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped
;;; End GNU ELPA

;; No `(provide 'haskell)' — the haskell-mode package ships its own haskell.el
;; that owns the `haskell' feature; this file is loaded by path from init.el, so
;; a provide isn't needed.
;;; haskell.el ends here
