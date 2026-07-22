;;; typescript.el --- JavaScript / TypeScript development extras  -*- lexical-binding: t; -*-

;; Optional JS/TS layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. One file covers both
;; languages: they share a language server, a debug adapter, and tooling, so
;; splitting them would only duplicate config. Handles .js / .jsx / .ts / .tsx.
;;
;; Most of the stack is built in: the tree-sitter major modes (js-ts-mode,
;; typescript-ts-mode, tsx-ts-mode) and eglot, which init.el already hooks onto
;; prog-mode. You supply the external tools:
;;   - typescript-language-server (npm i -g typescript typescript-language-server)
;;     — eglot launches it automatically for js/jsx/ts/tsx once it's on PATH; the
;;     one server handles both JavaScript and TypeScript
;;   - the vscode-js-debug adapter — driven here by dape for breakpoints/stepping
;;   - the tree-sitter grammars: `M-x treesit-install-language-grammar RET
;;     javascript' (then `typescript', `tsx') — the repo URLs (incl. the
;;     typescript/src and tsx/src subdirs) are pre-registered in :init, so
;;     there's no URL prompt; until installed, .js falls back to js-mode and
;;     .ts/.tsx aren't auto-detected
;;
;; ELPA-only: dape is on GNU ELPA; the major modes and eglot are built in.
;; (typescript-mode / tide / lsp-* are MELPA-only, so they're not used here.)

;;; Built-in
;; JavaScript + JSX → js-ts-mode (the built-in js.el tree-sitter mode).
(use-package js
  :ensure nil
  :init
  ;; Register the grammar source (no URL prompt on install); remap the js majors
  ;; to js-ts-mode once the grammar exists.
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(javascript "https://github.com/tree-sitter/tree-sitter-javascript"))
    (when (treesit-language-available-p 'javascript)
      (dolist (m '(js-mode javascript-mode js-jsx-mode))
        (add-to-list 'major-mode-remap-alist (cons m 'js-ts-mode)))))
  :custom
  (js-indent-level 2))

;; TypeScript → typescript-ts-mode, TSX → tsx-ts-mode. Emacs doesn't bind .ts /
;; .tsx by default, so wire them up (only when the grammar is built — eglot
;; still attaches even if a file opens in fundamental-mode).
(use-package typescript-ts-mode
  :ensure nil
  :init
  ;; Both grammars live in ONE repo, under typescript/src and tsx/src — encode
  ;; those subdirs so install needs no URL. Bind the ts-modes once built.
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(typescript "https://github.com/tree-sitter/tree-sitter-typescript"
                              nil "typescript/src"))
    (add-to-list 'treesit-language-source-alist
                 '(tsx "https://github.com/tree-sitter/tree-sitter-typescript"
                       nil "tsx/src"))
    (when (treesit-language-available-p 'typescript)
      (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode)))
    (when (treesit-language-available-p 'tsx)
      (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))))
  :custom
  (typescript-ts-mode-indent-offset 2))
;;; End Built-in

;;; GNU ELPA
;; DAP-based debugging that pairs with eglot (no lsp-mode needed). To debug:
;; M-x dape, choose a `js-debug-*' config (Node or Chrome; it uses the
;; vscode-js-debug adapter). Set breakpoints with `dape-breakpoint-toggle';
;; n / c step once a session stops.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped
;;; End GNU ELPA

(provide 'typescript)
;;; typescript.el ends here
