;;; erlang.el --- Erlang development extras  -*- lexical-binding: t; -*-

;; Optional Erlang layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it.
;;
;; Erlang is the odd one out. There is no built-in tree-sitter mode for it, and
;; the canonical `erlang-mode' (erlang.el) is NOT on GNU/NonGNU ELPA — it ships
;; INSIDE Erlang/OTP, under `<otp>/lib/tools-<ver>/emacs/'. (The MELPA `erlang'
;; package is that same file, but this config never uses MELPA.) So this layer
;; puts OTP's own emacs/ directory on `load-path' and loads that erlang.el. You
;; supply the external tools:
;;   - Erlang/OTP — provides `erl' and the bundled erlang.el / erlang-mode
;;   - erlang_ls — put it on PATH and eglot launches it automatically (eglot's
;;     built-in Erlang entry runs `erlang_ls --transport stdio') for
;;     completion / xref / hovers
;;
;; No tree-sitter grammar step (there is no erlang-ts-mode). No dape wiring:
;; Erlang has no standard DAP adapter — debug with OTP's own tools instead
;; (`debugger:start().' for the GUI, or `int:i/1' + `int:break/2' from a shell).
;; Rebar3 / erlang.mk builds run through M-x project-compile.

;;; Erlang/OTP-bundled erlang-mode  (not ELPA — see header)
(defun my-erlang--otp-emacs-dir ()
  "Return OTP's bundled emacs/ directory (home of erlang.el), or nil.
Ask `erl' for the `tools' application lib dir and append emacs/."
  (when (executable-find "erl")
    (let ((dir (ignore-errors
                 (string-trim
                  (shell-command-to-string
                   "erl -noshell -eval 'io:format(\"~s\", [filename:join(code:lib_dir(tools), \"emacs\")])' -s init stop")))))
      (and (stringp dir) (file-directory-p dir) dir))))

;; Load OTP's erlang.el: try `load-path' first (site config / a hardcoded
;; entry), else ask `erl' where OTP keeps it. This file is loaded by path and
;; does NOT `(provide 'erlang)', so `(require 'erlang)' here always resolves to
;; OTP's copy, never to this file. If auto-detect misses (unusual OTP layout),
;; hardcode it:  (add-to-list 'load-path "/path/to/otp/lib/tools-<ver>/emacs")
(unless (require 'erlang nil t)
  (when-let* ((dir (my-erlang--otp-emacs-dir)))
    (add-to-list 'load-path dir)
    (require 'erlang nil t)))

(when (featurep 'erlang)
  (setq erlang-indent-level 4)
  ;; erlang.el registers most of these itself; harmless to ensure them.
  (dolist (entry '(("\\.erl\\'"              . erlang-mode)
                   ("\\.hrl\\'"              . erlang-mode)
                   ("\\.app\\(\\.src\\)?\\'" . erlang-mode)
                   ("/rebar\\.config\\'"     . erlang-mode)))
    (add-to-list 'auto-mode-alist entry)))
;; eglot auto-starts from init.el's prog-mode hook (modern erlang-mode derives
;; from prog-mode). On an older erlang.el that doesn't, add:
;;   (add-hook 'erlang-mode-hook #'eglot-ensure)

;; No `(provide 'erlang)' — the feature/library name `erlang' belongs to OTP's
;; own erlang.el; this file is loaded by path, so providing it would shadow the
;; real one. (Same reason cpp.el / python.el / go.el skip their provides.)
;;; erlang.el ends here
