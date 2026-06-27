;;; erlang.el --- Erlang development extras  -*- lexical-binding: t; -*-

;; Optional Erlang layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. (Elixir lives in its
;; own elixir.el — same BEAM runtime, but no shared Emacs tooling.)
;;
;; Erlang is the odd one out twice over: Emacs has no built-in mode, and
;; erlang-mode is on no package archive either — it ships *with the Erlang/OTP
;; install* (under <otp>/lib/tools-*/emacs/). So this file finds that bundled
;; mode and puts it on the load-path; nothing comes from MELPA. You supply:
;;   - Erlang/OTP (the `erl' binary on PATH — also how the mode is located)
;;   - erlang_ls, the Erlang language server — eglot launches it once on PATH
;;
;; Set `my/erlang-otp-emacs-dir' to skip the one-time `erl' shell-out at startup.
;;
;; ELPA-only: eglot is built in; erlang-mode comes from OTP, not a package
;; archive. (Debugging: see the note below.)

;;; OTP-bundled erlang-mode
(defvar my/erlang-otp-emacs-dir nil
  "Directory holding OTP's bundled erlang-mode. nil → autodetect via `erl'.")

(defun my/erlang--otp-emacs-dir ()
  "Return OTP's bundled erlang-mode Emacs directory, or nil."
  (or my/erlang-otp-emacs-dir
      (when (executable-find "erl")
        (let ((dir (string-trim
                    (shell-command-to-string
                     (concat "erl -noshell"
                             " -eval 'io:format(\"~s\", [code:lib_dir(tools, emacs)])'"
                             " -s init stop")))))
          (and (file-directory-p dir) dir)))))

(let ((dir (my/erlang--otp-emacs-dir)))
  (when dir
    (add-to-list 'load-path dir)
    (autoload 'erlang-mode "erlang" "Major mode for editing Erlang code." t)
    (dolist (pat '("\\.erl\\'" "\\.hrl\\'" "\\.app\\(?:\\.src\\)?\\'"
                   "/rebar\\.config\\'" "\\.escript\\'"))
      (add-to-list 'auto-mode-alist (cons pat 'erlang-mode)))))
;;; End OTP-bundled erlang-mode

;;; Built-in
;; eglot ships no Erlang entry — point it at erlang_ls.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(erlang-mode . ("erlang_ls"))))
;;; End Built-in

;;; Debugging
;; No DAP config here: dape ships none for Erlang, and erlang_ls's els_dap is
;; niche. To debug, use OTP's graphical debugger (eval `debugger:start()' then
;; `int:i(Module)'), or register an els_dap dape config yourself, e.g.:
;;   (with-eval-after-load 'dape
;;     (add-to-list 'dape-configs
;;       '(els-dap modes (erlang-mode) ensure dape-ensure-command
;;                 command "els_dap" :type "erlang" :request "launch")))
;;; End Debugging

;; No `(provide 'erlang)' — OTP's bundled erlang.el owns the `erlang' feature;
;; this file is loaded by path from init.el, so a provide isn't needed.
;;; erlang.el ends here
