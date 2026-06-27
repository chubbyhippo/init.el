;;; php.el --- PHP development extras  -*- lexical-binding: t; -*-

;; Optional PHP layer for init.el. Disabled by default — uncomment the matching
;; loader at the bottom of init.el to enable it.
;;
;; The major mode (php-ts-mode) is built into Emacs 30, and eglot is built in
;; too — init.el already hooks it onto prog-mode. You supply the external tools:
;;   - a PHP language server: intelephense (npm i -g intelephense) or phpactor —
;;     eglot launches whichever it finds on PATH
;;   - the vscode-php-debug adapter (run via node) plus Xdebug in your PHP
;;     runtime — driven here by dape for breakpoints/stepping
;;   - the tree-sitter grammars — M-x php-ts-mode-install-parsers fetches them
;;     all (php, phpdoc, html, css, javascript, jsdoc) in one go
;;
;; ELPA-only: dape is on GNU ELPA; php-ts-mode and eglot are built in.
;; (php-mode is MELPA-only, so it's not used here.)

;;; Built-in
;; php-ts-mode already claims .php / .phtml / .inc / … via its autoloads — it
;; dispatches through php-ts-mode-maybe, using php-ts-mode when the grammar is
;; built and falling back otherwise. So nothing to bind here; just point eglot
;; at a server, since it ships no PHP entry (first one found on PATH wins).
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `(php-ts-mode . ,(eglot-alternatives
                                 '(("intelephense" "--stdio")
                                   ("phpactor" "language-server"))))))
;;; End Built-in

;;; GNU ELPA
;; DAP-based debugging that pairs with eglot (no lsp-mode needed). To debug:
;; M-x dape, choose the `xdebug' config — it runs the vscode-php-debug adapter
;; (via node, from dape's adapter dir) and listens for Xdebug on port 9003, so
;; you need node, that adapter, and Xdebug enabled in PHP. Set breakpoints with
;; `dape-breakpoint-toggle'; n / c step once a session stops.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped
;;; End GNU ELPA

(provide 'php)
;;; php.el ends here
