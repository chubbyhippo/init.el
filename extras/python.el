;;; python.el --- Python development extras  -*- lexical-binding: t; -*-

;; Optional Python layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it.
;;
;; Built in: the major mode (python / python-ts-mode) and eglot, which init.el
;; already hooks onto prog-mode. You supply the external tools:
;;   - an LSP server such as python-lsp-server (pylsp) or pyright — eglot uses
;;     whichever it finds for completion / xref / refactors
;;   - debugpy (pip install debugpy) for the dape debugger
;;
;; The fiddly part of Python in Emacs is the per-project virtualenv. buffer-env
;; handles it: it activates the project's venv (or .envrc) buffer-locally, so
;; eglot, dape, flymake, and run-python all use the right interpreter with no
;; global state. Everything here is on GNU ELPA (no MELPA needed).

;;; Built-in
(use-package python
  :ensure nil
  :init
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'python))
    (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))
  :custom
  (python-indent-guess-indent-offset-verbose nil)) ; quiet the indent-guess warning
;;; End Built-in

;;; GNU ELPA
;; Activate the project's virtualenv buffer-locally so the LSP / debugger / REPL
;; all use it. Honours direnv (.envrc) out of the box; the :config below also
;; teaches it to source a plain .venv/bin/activate.
(use-package buffer-env
  :ensure t
  :hook ((hack-local-variables . buffer-env-update)  ; set env when a project file opens
         (comint-mode          . buffer-env-update))  ; ...and in REPL / shell buffers
  :custom
  (buffer-env-script-name '(".envrc" ".venv/bin/activate")) ; searched up the directory tree
  :config
  (add-to-list 'buffer-env-command-alist
               '("/bin/activate\\'" . "set -a && . \"$0\" && env -0")))

;; DAP debugging that pairs with eglot (no lsp-mode needed). M-x dape, pick the
;; `debugpy' config; set breakpoints with dape-breakpoint-toggle, then n / c to
;; step once a session stops.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped

;; Optional, also on GNU ELPA — Jupyter-style `# %%' cells for data-science work:
;; (use-package code-cells :ensure t :hook ((python-mode python-ts-mode) . code-cells-mode))
;;; End GNU ELPA

;; No `(provide 'python)' here — the built-in python.el already owns that
;; feature name; this file is loaded by path from init.el, so it isn't needed.
;;; python.el ends here
