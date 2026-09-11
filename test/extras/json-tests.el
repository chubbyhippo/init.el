;;; json-tests.el --- ERT suite for extras/json.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/json.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional JSON layer for init.el. Disabled by default — uncomment the
;; matching loader in extras.el to enable it. Handles .json.
;;
;; Everything here is built in: json-ts-mode (Emacs 29+) and eglot, which
;; init.el already hooks onto prog-mode — json-ts-mode derives from prog-mode,
;; so that global hook reaches it with no extra work here. eglot's own table
;; already maps json-ts-mode (and the classic js-json-mode/json-mode/jsonc-mode)
;; to vscode-json-language-server, so nothing to register here either.
;;
;; The one thing Emacs core does NOT do automatically is bind .json to
;; json-ts-mode at startup: json-ts-mode.el's own auto-mode-alist entry is a
;; plain top-level form, not wrapped in an autoload cookie, so it only takes
;; effect once the file has actually been loaded. This layer's :mode keyword
;; registers the association directly instead of waiting on that.
;;
;; ELPA-only: nothing is required from ELPA at all; json-ts-mode and eglot are
;; both built in. (json-mode is on GNU ELPA if you ever want the classic,
;; non-tree-sitter mode instead, but it is not needed here.)
;;
;; You supply the external tool:
;;   - vscode-json-language-server, from `npm i -g vscode-langservers-extracted'
;;     — eglot already knows it
;;   - the json tree-sitter grammar — AUTO-INSTALLED on first load (needs git +
;;     a C compiler on PATH)
;;
;; No dape config: JSON is data, not executable code.
;;
;; No `(provide 'json)' in the extras file — `json' is Emacs's own built-in
;; JSON-parsing library feature name (json.el, used internally by jsonrpc and
;; many packages); providing it again here would risk shadowing that.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; =================================================================== json.el
(ert-deftest extras-test/given-json-then-dot-json-maps-to-json-ts-mode ()
  (should (member "\\.json\\'"
                  (extras-test--use-package-section "json.el" 'json-ts-mode :mode))))

(ert-deftest extras-test/given-json-then-the-json-grammar-is-registered-and-installed ()
  (should (extras-test--declares
           "json.el" '(json "https://github.com/tree-sitter/tree-sitter-json")))
  (should (extras-test--declares "json.el" '(treesit-install-language-grammar 'json))))

(provide 'json-tests)
;;; json-tests.el ends here
