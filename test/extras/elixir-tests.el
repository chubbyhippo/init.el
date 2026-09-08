;;; elixir-tests.el --- ERT suite for extras/elixir.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Chubby Hippo
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
;; more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <https://www.gnu.org/licenses/>.
;;
;; SPDX-License-Identifier: GPL-3.0-or-later

;; Guide retained from extras/elixir.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
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
;;     breakpoints / stepping through a mix task; see the dape config tested
;;     below
;;   - the tree-sitter grammars (elixir, heex) — AUTO-INSTALLED on first load
;;     from the sources registered in :init (needs git + a C compiler on PATH);
;;     until they build, .ex/.exs/.heex aren't auto-detected
;;
;; ELPA-only: dape is on GNU ELPA; the major modes and eglot are built in.
;; (elixir-mode lives on NonGNU ELPA but is unneeded now that elixir-ts-mode is
;; in core.) Mix commands run through M-x project-compile / compile.
;;
;; `mix format' on save runs via the language server, and only fires when
;; eglot is actually managing the buffer — see the format-on-save test below.
;;
;; The dape wrapper mirrors dape's own built-in configs: the keys
;; (modes/ensure/command/command-cwd) and the function-valued
;; `dape-command-cwd' come straight from dape; the `:type'/`:task'/…
;; keys are ElixirLS's `mix_task' launch schema. To debug: M-x dape, pick
;; `elixir-ls'; change `:task'/`:taskArgs'/`:requireFiles' for a non-test run
;; (e.g. :task "phx.server"). Breakpoints with `dape-breakpoint-toggle'; n / c.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================ elixir.el
(ert-deftest extras-test/given-elixir-then-format-on-save-only-formats-when-eglot-manages-it ()
  (extras-test--eval-def "elixir.el" 'defun 'my-elixir--format-on-save)
  (let ((fn (extras-test--capture-before-save-hook-fn #'my-elixir--format-on-save)))
    (let (called)
      (cl-letf (((symbol-function 'eglot-managed-p) (lambda () nil))
                ((symbol-function 'eglot-format-buffer) (lambda (&rest _) (setq called t))))
        (funcall fn))
      (should-not called))
    (let (called)
      (cl-letf (((symbol-function 'eglot-managed-p) (lambda () t))
                ((symbol-function 'eglot-format-buffer) (lambda (&rest _) (setq called t))))
        (funcall fn))
      (should called))))

(ert-deftest extras-test/given-elixir-then-ex-and-exs-map-to-elixir-ts-mode ()
  (should (extras-test--declares "elixir.el" '("\\.exs?\\'" . elixir-ts-mode)))
  (should (extras-test--declares "elixir.el" '("\\.heex\\'" . heex-ts-mode))))

(ert-deftest extras-test/given-elixir-then-dape-gets-an-elixir-ls-mix-task-config ()
  (should (extras-test--declares "elixir.el" :task))
  (should (extras-test--declares "elixir.el" "debug_adapter.sh")))

(ert-deftest extras-test/given-elixir-then-it-provides-elixir ()
  (should (extras-test--declares "elixir.el" '(provide 'elixir))))

(provide 'elixir-tests)
;;; elixir-tests.el ends here
