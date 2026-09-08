;;; html-tests.el --- ERT suite for extras/html.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/html.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional HTML/CSS layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. One file covers both:
;; they share the same npm package for their language servers and are edited
;; together. Handles .html / .htm and .css (.scss keeps the built-in scss-mode).
;;
;; Every major mode here is ALREADY built in — mhtml-mode, html-mode, css-mode,
;; css-ts-mode, html-ts-mode all ship with Emacs 30 — so this layer is thin. It
;; exists for one reason that is easy to miss:
;;
;;   THE HTML MODES DERIVE FROM text-mode, NOT prog-mode.
;;   init.el hooks eglot onto prog-mode, so CSS buffers get a language server
;;   automatically and HTML buffers get NOTHING. This file adds the missing
;;   hook on html-mode, which mhtml-mode and html-ts-mode inherit -- that is
;;   exactly what the test below pins down.
;;
;; You supply the external tools:
;;   - vscode-html-language-server and vscode-css-language-server, both from
;;     `npm i -g vscode-langservers-extracted' — eglot already knows them: its
;;     built-in table maps html-mode and (css-mode css-ts-mode) to them
;;   - the css tree-sitter grammar — AUTO-INSTALLED on first load (needs git +
;;     a C compiler on PATH); until it builds, .css stays in the classic
;;     css-mode, which eglot drives just as well
;;
;; NO debug adapter, and none is wanted: HTML and CSS are not executed. Browser
;; debugging lives in extras/typescript.el, whose dape `js-debug-chrome' config
;; drives Chrome for the page's JavaScript.
;;
;; .html deliberately stays in mhtml-mode rather than html-ts-mode: only
;; mhtml-mode wires up the embedded <script>/<style> submodes, so a tree-sitter
;; remap would LOSE JS and CSS editing inside a page. The html grammar source is
;; registered anyway, so `M-x treesit-install-language-grammar html' needs no
;; URL if you ever want the plain tree-sitter mode. (Emacs 31's mhtml-ts-mode is
;; the one that finally combines both; revisit this when it lands.)
;;
;; ELPA-only: nothing is required from ELPA at all. emmet-mode, impatient-mode
;; and skewer-mode are MELPA-only, so they are not used here. web-mode IS on
;; NonGNU ELPA but is unneeded now that mhtml-mode handles the submodes.
;;
;; Only css is registered for tree-sitter auto-install, not html — html-ts-mode
;; is deliberately unused (see above), so its grammar would be dead weight.
;;
;; No `(provide 'html)' in the extras file — `html' is as generic a feature
;; name as `go', and it is loaded by path from init.el, so a provide would
;; only invite a clash.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================= html.el
(ert-deftest extras-test/given-html-then-html-mode-gets-the-missing-eglot-hook ()
  "html-mode derives from text-mode, so init.el's prog-mode hook never fires
for it; this file's whole reason to exist is patching that gap directly."
  (should (member '(html-mode . eglot-ensure)
                  (extras-test--use-package-section "html.el" 'sgml-mode :hook)))
  (should (member '(sgml-basic-offset 2)
                  (extras-test--use-package-section "html.el" 'sgml-mode :custom))))

(ert-deftest extras-test/given-html-then-css-remaps-to-its-tree-sitter-mode ()
  (should (extras-test--declares "html.el" '(css-mode . css-ts-mode)))
  (should (member '(css-indent-offset 2)
                  (extras-test--use-package-section "html.el" 'css-mode :custom))))

(provide 'html-tests)
;;; html-tests.el ends here
