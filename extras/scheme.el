;;; scheme.el --- Scheme development extras (Guile, SICP)  -*- lexical-binding: t; -*-

;; Optional Scheme layer for init.el — Guile as the default Scheme, with Chez
;; kept active for SICP. Disabled by default — uncomment the matching loader at
;; the bottom of init.el to enable it. Every package here is on NonGNU ELPA, so
;; it installs through the same `package' / `use-package' setup as the rest of
;; the config (no MELPA needed).
;;
;;   scheme-mode   the major mode — BUILT IN (Emacs already maps .scm to it),
;;                 so nothing to install just to edit
;;   geiser        the interactive layer: REPL, eval-in-buffer, autodoc,
;;                 completion, jump-to-def — the "develop Scheme" piece
;;   geiser-guile  the Guile backend — the default implementation below
;;   geiser-chez   the Chez Scheme backend
;;   paredit       keep the parens balanced while you edit
;;
;; You supply the interpreters:
;;   Guile  `sudo apt install guile-3.0' (already in wsl-ubuntu-settings'
;;          apt.sh); it provides plain `guile' via update-alternatives, which
;;          is geiser-guile's default binary — nothing to set here. Add
;;          `guile-3.0-doc' and `M-x geiser-doc-look-up-manual' jumps from any
;;          symbol into the Guile Info manual — the manual is the course.
;;   Chez   `sudo apt install chezscheme'. The Ubuntu package installs the
;;          binary as `chezscheme', which is why `geiser-chez-binary' is set
;;          below.
;;
;; C-c C-z starts (or jumps to) the REPL for the buffer's implementation —
;; Guile unless the buffer says otherwise; eval a defun with C-M-x, the last
;; sexp with C-x C-e. `M-x run-guile' / `M-x run-chez' start a specific REPL.
;;
;; SICP on Chez: its REPL runs most of the book (mutable pairs and top-level
;; redefinition are allowed) — pin SICP buffers to it with a file-local
;; `geiser-scheme-implementation: chez' (declared safe, so no prompt). The
;; ch.2.2.4 picture language and a few MIT-isms (`cons-stream',
;; `true'/`false'/`nil') still need small shims — or use MIT/GNU Scheme
;; (geiser-mit) or Racket's `#lang sicp' (geiser-racket), both NonGNU ELPA:
;; install the backend and add it to the two geiser vars below.

;;; NonGNU ELPA
(use-package geiser
  :ensure t
  :hook (scheme-mode . geiser-mode)          ; load + light up geiser in .scm buffers
  :custom
  (geiser-default-implementation 'guile)     ; what a plain .scm buffer gets
  (geiser-active-implementations '(guile chez)))

(use-package geiser-guile
  :ensure t
  :defer t)                                  ; binary defaults to plain `guile'

(use-package geiser-chez
  :ensure t
  :defer t
  :custom
  (geiser-chez-binary "chezscheme"))         ; the Ubuntu chezscheme package binary

(use-package paredit
  :ensure t
  :hook ((scheme-mode      . enable-paredit-mode)
         (geiser-repl-mode . enable-paredit-mode)))
;;; End NonGNU ELPA

;; scheme-mode is a `prog-mode' child, so init.el's global `my/eglot-ensure'
;; hook would fire and nag "no suitable server" — there is no Scheme LSP (geiser
;; provides eval / autodoc / completion). Opt Scheme buffers out of it via
;; advice, without editing init.el; guarded so load order doesn't matter.
(when (fboundp 'my/eglot-ensure)
  (advice-add 'my/eglot-ensure :before-while
              (lambda () (not (derived-mode-p 'scheme-mode)))
              '((name . my/scheme--skip-eglot))))

;; No `(provide 'scheme)' — the feature/library name `scheme' belongs to the
;; built-in scheme.el (it defines scheme-mode); this file is loaded by path from
;; init.el, so providing it would shadow the built-in. (Same reason cpp.el /
;; python.el / go.el / erlang.el skip their provides.)
;;; scheme.el ends here
