;;; ruby-tests.el --- ERT suite for extras/ruby.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/ruby.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional Ruby layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. Handles .rb,
;; Gemfile, Rakefile and .gemspec — Emacs's own ruby-mode already binds these.
;;
;; Most of the stack is built in: the major mode (ruby-mode, or the
;; tree-sitter ruby-ts-mode) and eglot, which init.el already hooks onto
;; prog-mode — eglot's own table already maps ruby-mode/ruby-ts-mode to
;; Solargraph, so nothing to register here. You supply the external tools:
;;   - solargraph (`gem install solargraph`) — eglot launches it automatically
;;     for completion / xref / hover once it's on PATH (ruby-lsp is a drop-in
;;     alternative; point eglot at it yourself via eglot-server-programs if
;;     you'd rather use that instead)
;;   - the `debug` gem (`gem install debug`), which provides `rdbg` — dape
;;     already ships an `rdbg` config for ruby-mode/ruby-ts-mode, so nothing
;;     to register here either
;;   - the tree-sitter grammar (ruby) — AUTO-INSTALLED on first load from the
;;     source registered in :init (needs git + a C compiler on PATH); until it
;;     builds, .rb files stay on the classic ruby-mode
;;
;; ELPA-only: inf-ruby is on NonGNU ELPA; dape and rubocop are on GNU ELPA (or
;; NonGNU — see below); the major mode and eglot are built in. (robe and
;; rspec-mode are MELPA-only, so they're not used here.)
;;
;; Upgrading ruby-mode to ruby-ts-mode happens once the grammar is built.
;; Emacs already maps .rb / Gemfile / Rakefile / .gemspec to ruby-mode, so a
;; remap is enough — no auto-mode-alist fiddling needed; ruby-ts-mode.el does
;; the rest via major-mode-remap-defaults once treesit-ready-p sees the
;; grammar.
;;
;; inf-ruby fills the interactive layer Ruby has no built-in equivalent for:
;; a comint REPL, eval-in-buffer, and jump-to-the-REPL — the same slot geiser
;; fills for Scheme and CIDER for Clojure. C-c C-z starts/jumps to it; C-c C-r
;; eval region.
;;
;; dape's built-in `rdbg' config runs the `debug' gem's server under
;; whatever Ruby command you give it (defaults to the current buffer; edit
;; its `-c' entry for `bundle exec rake test' or `rails server'). To debug:
;; M-x dape, choose `rdbg'. Set breakpoints with `dape-breakpoint-toggle';
;; n / c step once a session stops.
;;
;; Optional, also on NonGNU ELPA — RuboCop's own commands (check/autocorrect/
;; format, project/directory/current-file variants) under a C-c C-r prefix,
;; plus opt-in autocorrect/format-on-save hooks. Results land in a compilation
;; buffer with next-error navigation, not inline flymake diagnostics — this is
;; NOT a linter backend, just the M-x wrapper. Uncomment to enable (needs the
;; rubocop gem on PATH):
;;   (use-package rubocop
;;     :ensure t
;;     :hook ((ruby-mode ruby-ts-mode) . rubocop-mode))
;;
;; `ruby' is a free, specific feature name — no built-in file or ELPA package
;; provides it (Emacs's own modes live in ruby-mode.el / ruby-ts-mode.el,
;; which provide `ruby-mode' / `ruby-ts-mode'); the extras file provides it
;; anyway, as a courtesy, not a requirement. (Same reasoning as cobol.el;
;; joins clojure / elixir / java / rust / typescript / zig.)

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================= ruby.el
(ert-deftest extras-test/given-ruby-then-inf-ruby-hooks-into-both-ruby-majors ()
  (should (member '((ruby-mode ruby-ts-mode) . inf-ruby-minor-mode)
                  (extras-test--use-package-section "ruby.el" 'inf-ruby :hook))))

(ert-deftest extras-test/given-ruby-then-it-provides-ruby ()
  (should (extras-test--declares "ruby.el" '(provide 'ruby))))

(provide 'ruby-tests)
;;; ruby-tests.el ends here
