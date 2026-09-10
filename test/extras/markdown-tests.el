;;; markdown-tests.el --- ERT suite for extras/markdown.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/markdown.el (moved here when that file's
;; comments were stripped, so the rationale below still documents the tests
;; that pin its behavior down):
;;
;; Optional Markdown layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. Handles .md and
;; .markdown.
;;
;; Emacs core has no built-in Markdown mode at all -- not even a tree-sitter
;; one yet (markdown-ts-mode only lands in Emacs 32) -- so the major mode
;; itself comes from ELPA here, unlike json.el/yaml.el/html.el.
;;
;;   MARKDOWN-MODE DERIVES FROM text-mode, NOT prog-mode.
;;   init.el hooks eglot onto prog-mode, so Markdown buffers get NOTHING from
;;   that global hook. This file adds the missing hook directly on
;;   markdown-mode -- the same gap extras/html.el patches for html-mode, and
;;   extras/yaml.el patches for yaml-ts-mode. gfm-mode (GitHub-flavoured,
;;   used for README.md by some setups) derives from markdown-mode and
;;   inherits the hook the same way mhtml-mode inherits html.el's.
;;
;; eglot's own table already maps markdown-mode to marksman (falling back to
;; vscode-markdown-language-server), so nothing to register for that here.
;;
;; ELPA-only: markdown-mode is on NonGNU ELPA.
;;
;; You supply the external tool:
;;   - marksman (https://github.com/artempyanykh/marksman) — eglot already
;;     knows it; vscode-markdown-language-server (from
;;     `npm i -g vscode-markdown-languageserver') works as a fallback
;;
;; No dape config: Markdown is prose, not executable code.
;;
;; No `(provide 'markdown)' in the extras file -- markdown-mode.el itself
;; already provides `markdown-mode', not the bare `markdown' name, but this
;; layer is loaded by path from init.el like every other extras file, so a
;; provide is not needed for it to work.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; =============================================================== markdown.el
(ert-deftest extras-test/given-markdown-then-dot-md-and-markdown-map-to-markdown-mode ()
  (should (member '("\\.md\\'" "\\.markdown\\'")
                  (extras-test--use-package-section "markdown.el" 'markdown-mode :mode))))

(ert-deftest extras-test/given-markdown-then-it-gets-the-missing-eglot-hook ()
  "markdown-mode derives from text-mode, so init.el's prog-mode hook never
fires for it; this hooks my-eglot-ensure directly instead."
  (should (member '(markdown-mode . my-eglot-ensure)
                  (extras-test--use-package-section "markdown.el" 'markdown-mode :hook))))

(ert-deftest extras-test/given-markdown-then-code-blocks-fontify-natively ()
  (should (member '(markdown-fontify-code-blocks-natively t)
                  (extras-test--use-package-section "markdown.el" 'markdown-mode :custom))))

(provide 'markdown-tests)
;;; markdown-tests.el ends here
