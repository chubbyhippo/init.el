;;; sql-tests.el --- ERT suite for extras/sql.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/sql.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional SQL layer for init.el. Disabled by default -- uncomment the
;; matching loader in extras.el to enable it. `sql-mode' is
;; built in and already covers .sql via its own default auto-mode-alist
;; entry, so unlike most other extras/*.el this layer adds no :mode, :hook
;; or major-mode work of its own -- only LSP wiring.
;;
;; There is NO tree-sitter path -- same "not a yet" situation as cobol.el.
;; Emacs 30/31 ship no sql-ts-mode, and the one third-party grammar
;; (DerekStride/tree-sitter-sql) has no consuming mode on GNU or NonGNU
;; ELPA, only GitHub-only packages (sql-ts-mode et al) this config's
;; "never MELPA / ELPA only" rule excludes.
;;
;; You supply the external tool: sqls (github.com/sqls-server/sqls, Go,
;; MIT), the one SQL language server the Eglot community actually wires up
;; (eglot itself ships no SQL entry at all -- unlike cobol.el there is not
;; even an upstream eglot-<lang>.el to borrow the invocation from). It talks
;; stdio unconditionally, no flags needed, so the registration is the
;; shortest of any layer here: `("sqls")'.
;;
;; WHY THE eglot HOOK IS GUARDED. sql-mode derives from prog-mode, so
;; init.el's global `my-eglot-ensure' fires in every SQL buffer; without a
;; guard that means "Searching for program: ... sqls" in *Warnings* on every
;; .sql file until the server is actually installed. Same shape of advice as
;; cobol.el (skip until the binary exists) rather than scheme.el's
;; unconditional skip (which is for a language with no LSP story at all).
;;
;; sql-product decides dialect-specific font-lock/abbrevs and is declared
;; :safe, so a per-project .dir-locals.el entry works without any config
;; here; this layer intentionally sets no default so it does not bias one
;; dialect (postgres/mysql/sqlite/...) over another.
;;
;; sqls ITSELF is not dialect-specific -- it supports MySQL, PostgreSQL
;; (via pgx), SQLite3, MSSQL, H2, and Vertica, chosen per CONNECTION, not
;; per Emacs mode. None of that lives in this repo: sqls reads its own YAML
;; config, independent of sql-product/sql-mode.
;;
;; Config file, in priority order: the `-config' flag on the sqls
;; invocation (highest priority; not set by this layer, so global config
;; applies unless you pass one yourself); the LSP client's
;; workspace/configuration (eglot does not send this); then the default at
;; $XDG_CONFIG_HOME/sqls/config.yml, or ~/.config/sqls/config.yml.
;;
;; Example ~/.config/sqls/config.yml for PostgreSQL:
;;
;;   connections:
;;     - alias: my_postgres
;;       driver: postgresql
;;       host: 127.0.0.1
;;       port: 5432
;;       user: postgres
;;       passwd: mysecretpassword
;;       dbName: mydb
;;       params:
;;         sslmode: disable
;;
;; Or with a raw DSN instead of individual fields (dataSourceName takes
;; precedence over host/port/user/passwd/dbName/params when both are set):
;;
;;   connections:
;;     - alias: my_postgres
;;       driver: postgresql
;;       dataSourceName: "host=127.0.0.1 port=5432 user=postgres password=mysecretpassword dbname=mydb sslmode=disable"
;;
;; `connections' is a list -- multiple entries (even mixing drivers) are
;; fine; the first one is the default at startup, and the LSP code actions
;; "Switch Connection" / "Switch Database" (bound to nothing here; reach
;; them via M-RET/eglot-code-actions) move between the rest at runtime.
;;
;; Per-project config is NOT auto-discovered (no .sqls.yml lookup) -- it
;; is done by pointing `-config' at a project-local yaml, e.g. adding a
;; contact function to eglot-server-programs (mirroring
;; my-typescript--lsp-contact in extras/typescript.el) that locates a
;; project-root sqls.yml and appends `-config' `<path>' to `("sqls")'.
;; This layer intentionally does not do that -- it registers only the
;; bare `("sqls")' invocation, so the global config always applies unless
;; you add project-local wiring yourself.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================== sql.el
(ert-deftest extras-test/given-sql-then-the-builtin-mode-is-used-unmodified ()
  "sql-mode is built in (:ensure nil) and needs no :mode/:hook/:custom here --
its own auto-mode-alist entry already covers .sql."
  (should (extras-test--declares "sql.el" '(use-package sql :ensure nil))))

(ert-deftest extras-test/given-sql-then-eglot-learns-sqls ()
  (let ((eglot-server-programs nil))
    (extras-test--eval-with-eval-after-load "sql.el" 'eglot)
    (should (equal (cdr (assoc 'sql-mode eglot-server-programs)) '("sqls")))))

(ert-deftest extras-test/given-sql-then-eglot-is-skipped-until-sqls-exists ()
  "The advice on my-eglot-ensure should hold eglot back in sql-mode buffers
until sqls is on PATH, and never touch other modes."
  (defun my-eglot-ensure () 'ran)
  (unwind-protect
      (progn
        (extras-test--eval-def "sql.el" 'when '(fboundp 'my-eglot-ensure))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest _) t))
                  ((symbol-function 'executable-find) (lambda (_) nil)))
          (should-not (my-eglot-ensure)))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest _) t))
                  ((symbol-function 'executable-find) (lambda (_) "/usr/bin/sqls")))
          (should (eq (my-eglot-ensure) 'ran)))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest _) nil)))
          (should (eq (my-eglot-ensure) 'ran))))
    (advice-remove 'my-eglot-ensure 'my-sql--skip-eglot-until-sqls)
    (fmakunbound 'my-eglot-ensure)))

(ert-deftest extras-test/given-sql-then-it-provides-sql ()
  (should (extras-test--declares "sql.el" '(provide 'sql))))

(provide 'sql-tests)
;;; sql-tests.el ends here
