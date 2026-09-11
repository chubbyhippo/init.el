;;; eglot-ensure-tests.el --- ERT suite for extras/eglot-ensure.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/eglot-ensure.el (moved here when that file's
;; comments were stripped, so the rationale below still documents the tests
;; that pin its behavior down):
;;
;; Shared helper, not a language layer of its own -- extras.el's menu never
;; lists it; every layer that needs it pulls it in itself via
;; `(require 'eglot-ensure (expand-file-name "extras/eglot-ensure" ...))',
;; so it works regardless of alphabetical load order in extras.el (the
;; obvious file name sorts between dotnet.el and elixir.el, ahead of most
;; of its callers, but `require' with an explicit file path does not care).
;;
;; Born from a real, verified bug: cobol.el/sql.el/kotlin.el/xml.el/
;; dotnet.el each independently hand-rolled the identical five-line
;; "hold my-eglot-ensure back until a binary exists" advice, and two other
;; layers with the exact same problem -- java.el and typescript.el, whose
;; custom eglot-server-programs entries also have NO built-in eglot
;; fallback (checked eglot-server-programs directly: nil for java-mode,
;; js-ts-mode, and typescript-ts-mode alike) -- had NO guard at all, so
;; opening a .java or .ts file before jdtls/typescript-language-server was
;; installed spammed *Warnings* with "Searching for program: ..." on every
;; file. This helper both de-duplicates the five copies and fixes the two
;; missing ones.
;;
;; NAMING: `-guard' was the first name tried, but neither the Emacs Lisp
;; Reference Manual's Coding Conventions nor GNU/NonGNU ELPA establish
;; "guard" as any kind of file/function naming idiom for this shape of
;; helper (Elisp's only documented `guard' is the unrelated `pcase' pattern,
;; `(guard BOOLEAN-EXPR)', a pcase-specific construct with no bearing here).
;; `ensure-' is the better-attested Lisp idiom for "make a precondition
;; hold before proceeding" (Alexandria's `ensure-function'/`ensure-list',
;; CLOS's `ensure-generic-function'), and reads naturally alongside the
;; `my-eglot-ensure' function this helper wraps -- hence
;; `my-eglot-ensure-once-ready' and this file's name.
;;
;; `my-eglot-ensure-once-ready' takes MODES (a mode symbol or list of them
;; -- `derived-mode-p' with multiple arguments already means "derives from
;; ANY of these", so a list just widens the check) and READY-P (a string,
;; checked via `executable-find', or a function of no arguments called
;; fresh on every my-eglot-ensure invocation). The function form exists
;; for typescript.el specifically: a plain executable-find on the bare
;; server name would miss a project-local node_modules/.bin copy, so its
;; own `my-typescript--lsp-ready-p' reuses `my-typescript--npm-bin's
;; resolution instead of duplicating it here.
;;
;; Each call returns the advice name it added (an uninterned symbol, via
;; `make-symbol' -- guaranteed unique per call even for repeated MODES, so
;; two guards never collide and advice-remove always targets the exact one
;; that was added), or nil if `my-eglot-ensure' is not yet defined (nothing
;; to advise). Guards on different mode/ready-p pairs coexist independently
;; -- each is its own `:before-while' advice, so one guard blocking never
;; affects another mode's buffers.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

(require 'eglot-ensure (extras-test-file "eglot-ensure.el"))

;;; ========================================================= eglot-ensure.el
(ert-deftest extras-test/given-eglot-ensure-then-it-provides-eglot-ensure ()
  (should (extras-test--declares "eglot-ensure.el" '(provide 'eglot-ensure))))

(ert-deftest extras-test/given-no-my-eglot-ensure-then-once-ready-is-a-no-op ()
  (fmakunbound 'my-eglot-ensure)
  (should-not (my-eglot-ensure-once-ready 'sql-mode "sqls")))

(ert-deftest extras-test/given-a-single-mode-and-a-string-then-it-blocks-until-on-path ()
  (defun my-eglot-ensure () 'ran)
  (unwind-protect
      (let ((name (my-eglot-ensure-once-ready 'sql-mode "sqls")))
        (should name)
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest modes) (memq 'sql-mode modes)))
                  ((symbol-function 'executable-find) (lambda (_) nil)))
          (should-not (my-eglot-ensure)))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest modes) (memq 'sql-mode modes)))
                  ((symbol-function 'executable-find) (lambda (b) (and (equal b "sqls") "/usr/bin/sqls"))))
          (should (eq (my-eglot-ensure) 'ran)))
        (advice-remove 'my-eglot-ensure name))
    (fmakunbound 'my-eglot-ensure)))

(ert-deftest extras-test/given-a-single-mode-then-other-modes-are-unaffected ()
  (defun my-eglot-ensure () 'ran)
  (unwind-protect
      (let ((name (my-eglot-ensure-once-ready 'sql-mode "sqls")))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest modes) (memq 'emacs-lisp-mode modes))))
          (should (eq (my-eglot-ensure) 'ran)))
        (advice-remove 'my-eglot-ensure name))
    (fmakunbound 'my-eglot-ensure)))

(ert-deftest extras-test/given-a-mode-list-then-any-match-blocks ()
  "MODES as a list -- java-ts-mode's registered parent is java-mode, so a
single-element list is the same shape typescript.el needs with three."
  (defun my-eglot-ensure () 'ran)
  (unwind-protect
      (let ((name (my-eglot-ensure-once-ready '(js-mode typescript-mode tsx-mode) "typescript-language-server")))
        (dolist (member-mode '(js-mode typescript-mode tsx-mode))
          (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest modes) (memq member-mode modes)))
                    ((symbol-function 'executable-find) (lambda (_) nil)))
            (should-not (my-eglot-ensure))))
        (advice-remove 'my-eglot-ensure name))
    (fmakunbound 'my-eglot-ensure)))

(ert-deftest extras-test/given-a-function-ready-p-then-it-is-called-fresh-each-time ()
  "READY-P as a function (typescript.el's shape): must reflect a value that
changes between calls, not just its value at registration time."
  (defun my-eglot-ensure () 'ran)
  (unwind-protect
      (let* ((ready nil)
             (name (my-eglot-ensure-once-ready 'sql-mode (lambda () ready))))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest modes) (memq 'sql-mode modes))))
          (should-not (my-eglot-ensure))
          (setq ready t)
          (should (eq (my-eglot-ensure) 'ran)))
        (advice-remove 'my-eglot-ensure name))
    (fmakunbound 'my-eglot-ensure)))

(ert-deftest extras-test/given-two-independent-guards-then-neither-leaks-into-the-other ()
  (defun my-eglot-ensure () 'ran)
  (unwind-protect
      (let ((name1 (my-eglot-ensure-once-ready 'sql-mode "sqls"))
            (name2 (my-eglot-ensure-once-ready 'kotlin-mode "kotlin-lsp")))
        (should-not (eq name1 name2))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest modes) (memq 'sql-mode modes)))
                  ((symbol-function 'executable-find) (lambda (b) (and (equal b "kotlin-lsp") "/x"))))
          (should-not (my-eglot-ensure)))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest modes) (memq 'kotlin-mode modes)))
                  ((symbol-function 'executable-find) (lambda (b) (and (equal b "sqls") "/x"))))
          (should-not (my-eglot-ensure)))
        (advice-remove 'my-eglot-ensure name1)
        (advice-remove 'my-eglot-ensure name2))
    (fmakunbound 'my-eglot-ensure)))

(ert-deftest extras-test/given-repeated-calls-with-identical-arguments-then-names-still-differ ()
  "Uninterned advice names (via make-symbol) stay unique even when MODES/
READY-P are identical across calls, so re-evaluating a layer (e.g. on
reload) never collides with its own earlier advice."
  (defun my-eglot-ensure () 'ran)
  (unwind-protect
      (let ((name1 (my-eglot-ensure-once-ready 'sql-mode "sqls"))
            (name2 (my-eglot-ensure-once-ready 'sql-mode "sqls")))
        (should-not (eq name1 name2))
        (advice-remove 'my-eglot-ensure name1)
        (advice-remove 'my-eglot-ensure name2))
    (fmakunbound 'my-eglot-ensure)))

(provide 'eglot-ensure-tests)
;;; eglot-ensure-tests.el ends here
