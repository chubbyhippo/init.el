;;; clojure.el --- Clojure development extras  -*- lexical-binding: t; -*-

;; Optional Clojure layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. Every package here is
;; on NonGNU ELPA, so it installs through the same `package' / `use-package'
;; setup as the rest of the config (no MELPA needed).
;;
;;   clojure-mode  major mode + indentation (paredit gives structural editing)
;;   cider         REPL, interactive eval, inspector, test runner, and the
;;                 step debugger — this is the "develop / debug Clojure" piece
;;   paredit       keep the parens balanced while you edit
;;
;; eglot already auto-starts on prog-mode (see init.el), so opening a .clj file
;; will try to launch clojure-lsp for static analysis/xref alongside CIDER's
;; REPL — install the clojure-lsp binary separately if you want that. CIDER on
;; its own needs only a JVM + a project (deps.edn / project.clj / shadow-cljs).

;;; NonGNU ELPA
(use-package clojure-mode
  :ensure t)
  ;; tree-sitter alternative: replace the form above with `clojure-ts-mode'
  ;; (also on NonGNU ELPA), then `M-x treesit-install-language-grammar clojure'.
  ;; If you switch, change the clojure-mode hooks below to clojure-ts-mode too.

(use-package cider
  :ensure t
  :hook (clojure-mode . cider-mode)            ; eval/debug keymap live in .clj buffers
  :custom
  (cider-repl-display-help-banner nil)         ; quieter REPL buffer
  (cider-repl-pop-to-buffer-on-connect 'display-only) ; show the REPL but keep point in the file
  (cider-save-file-on-load t)                  ; auto-save before C-c C-k loads a buffer
  (cider-show-error-buffer 'only-in-repl))     ; don't grab a window on every eval error
  ;; Start a REPL with C-c M-j (cider-jack-in). Then: C-c C-k load the file ·
  ;; C-c C-e eval the form before point · C-c C-z hop to the REPL. Debugger:
  ;; put point in a defn, hit C-u C-M-x to instrument it, run it, then step with
  ;; n (next) / c (continue) / q (quit).

(use-package paredit
  :ensure t
  :hook ((clojure-mode         . enable-paredit-mode)
         (cider-repl-mode       . enable-paredit-mode)
         (emacs-lisp-mode       . enable-paredit-mode)
         (lisp-interaction-mode . enable-paredit-mode)))

;; Also on NonGNU ELPA if you want them — uncomment to enable:
;; (use-package flymake-kondor   ; clj-kondo linting via flymake (needs the clj-kondo binary)
;;   :ensure t                   ; redundant if you let eglot drive clojure-lsp
;;   :hook (clojure-mode . flymake-kondor-setup))
;; (use-package inf-clojure :ensure t) ; bare-bones REPL, a lighter alternative to CIDER
;;; End NonGNU ELPA

(provide 'clojure)
;;; clojure.el ends here
