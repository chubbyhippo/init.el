;;; elixir.el --- Elixir development extras  -*- lexical-binding: t; -*-

;; Optional Elixir layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. (Erlang lives in its
;; own erlang.el — same BEAM runtime, but no shared Emacs tooling.)
;;
;; The major modes are built into Emacs 30: elixir-ts-mode (.ex / .exs, which it
;; self-binds) and heex-ts-mode (.heex templates). eglot is built in too. You
;; supply the external tools:
;;   - an Elixir language server: ElixirLS (launcher language_server.sh) or
;;     Next LS — eglot launches whichever it finds on PATH
;;   - ElixirLS's debug_adapter.sh — used by the dape config added below (dape
;;     ships no Elixir config, so this file registers one)
;;   - the tree-sitter grammars: M-x treesit-install-language-grammar RET elixir
;;     (then again for heex) — elixir-ts-mode registers both sources for you
;;
;; ELPA-only: dape is on GNU ELPA; the modes and eglot are built in. Elixir's
;; default indent is already 2, so there's nothing to configure mode-side.

;;; Built-in
;; elixir-ts-mode self-binds .ex / .exs / mix.lock via elixir-ts-mode-maybe
;; (which uses the tree-sitter mode once the grammar is built). eglot ships no
;; Elixir entry, so point it at a server — first one found on PATH wins.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `((elixir-ts-mode heex-ts-mode elixir-mode)
                 . ,(eglot-alternatives
                     '("language_server.sh"
                       "elixir-ls"
                       ("nextls" "--stdio"))))))
;;; End Built-in

;;; GNU ELPA
;; DAP-based debugging via dape. It ships no Elixir config, so register one for
;; ElixirLS's debug adapter (needs debug_adapter.sh on PATH). M-x dape →
;; `mix-test' runs `mix test' under the debugger; change :task (e.g. to "run")
;; or edit the config for other entry points. Breakpoints: dape-breakpoint-toggle.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped

(with-eval-after-load 'dape
  (add-to-list 'dape-configs
               '(mix-test
                 modes (elixir-ts-mode elixir-mode)
                 ensure dape-ensure-command
                 command "debug_adapter.sh"
                 :type "mix_task"
                 :request "launch"
                 :task "test"
                 :projectDir ".")))
;;; End GNU ELPA

(provide 'elixir)
;;; elixir.el ends here
