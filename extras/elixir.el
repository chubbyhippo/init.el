;;; elixir.el --- Elixir development extras  -*- lexical-binding: t; -*-

;; Optional Elixir layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it.
;;
;; Most of the stack is built in: the tree-sitter major modes (elixir-ts-mode,
;; and heex-ts-mode for Phoenix ~H / .heex templates — both ship with Emacs 30)
;; and eglot, which init.el already hooks onto prog-mode. You supply the
;; external tools:
;;   - ElixirLS — put its `language_server.sh' on PATH and eglot launches it
;;     automatically for completion / xref / refactors / formatting. (eglot's
;;     built-in Elixir entry also accepts Lexical's `start_lexical.sh' if you
;;     prefer that server.)
;;   - ElixirLS's `debug_adapter.sh' (same release) — driven here by dape for
;;     breakpoints / stepping through a mix task; see the dape config below
;;   - the tree-sitter grammars (M-x treesit-install-language-grammar RET elixir,
;;     then again for heex) — until then .ex/.exs/.heex aren't auto-detected
;;
;; ELPA-only: dape is on GNU ELPA; the major modes and eglot are built in.
;; (elixir-mode lives on NonGNU ELPA but is unneeded now that elixir-ts-mode is
;; in core.) Mix commands run through M-x project-compile / compile.

;;; Built-in
;; `mix format' on save, via the language server (only fires when eglot is up).
(defun my/elixir--format-on-save ()
  "Arrange for the language server to format the buffer before each save."
  (add-hook 'before-save-hook
            (lambda () (when (eglot-managed-p) (eglot-format-buffer)))
            nil t))

;; .ex/.exs → elixir-ts-mode, .heex → heex-ts-mode (Emacs binds neither until
;; the matching grammar is installed).
(use-package elixir-ts-mode
  :ensure nil
  :init
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'elixir))
    (add-to-list 'auto-mode-alist '("\\.exs?\\'" . elixir-ts-mode)))
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'heex))
    (add-to-list 'auto-mode-alist '("\\.heex\\'" . heex-ts-mode)))
  :hook (elixir-ts-mode . my/elixir--format-on-save))
;;; End Built-in

;;; GNU ELPA
;; DAP-based debugging that pairs with eglot (no lsp-mode needed). ElixirLS
;; ships a debug adapter (`debug_adapter.sh'); dape has no built-in Elixir
;; config, so we register one that runs a mix task under that adapter. The
;; wrapper keys (modes/ensure/command/command-cwd) and the function-valued
;; `dape-command-cwd' mirror dape's own built-in configs; the `:type'/`:task'/…
;; keys are ElixirLS's `mix_task' launch schema. To debug: M-x dape, pick
;; `elixir-ls'; change `:task'/`:taskArgs'/`:requireFiles' for a non-test run
;; (e.g. :task "phx.server"). Breakpoints with `dape-breakpoint-toggle'; n / c.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t)                      ; show variable values inline when stopped
  :config
  (add-to-list 'dape-configs
               `(elixir-ls
                 modes (elixir-ts-mode elixir-mode)
                 ensure dape-ensure-command
                 command "debug_adapter.sh"
                 command-cwd dape-command-cwd
                 :type "mix_task"
                 :request "launch"
                 :task "test"
                 :taskArgs ["--trace"]
                 :projectDir dape-command-cwd
                 :requireFiles ["test/**/test_helper.exs"
                                "test/**/*_test.exs"])))
;;; End GNU ELPA

(provide 'elixir)
;;; elixir.el ends here
