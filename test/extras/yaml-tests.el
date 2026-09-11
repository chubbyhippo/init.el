;;; yaml-tests.el --- ERT suite for extras/yaml.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/yaml.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional YAML layer for init.el. Disabled by default — uncomment the
;; matching loader in extras.el to enable it. Handles .yml/.yaml.
;;
;; The major mode (yaml-ts-mode, Emacs 29+) and eglot are both built in.
;; eglot's own table already maps yaml-ts-mode (and the classic yaml-mode) to
;; yaml-language-server, so nothing to register here for that.
;;
;;   YAML-TS-MODE DERIVES FROM text-mode, NOT prog-mode.
;;   init.el hooks eglot onto prog-mode, so YAML buffers get NOTHING from
;;   that global hook. This file adds the missing hook directly on
;;   yaml-ts-mode — the same gap extras/html.el patches for html-mode, and
;;   extras/markdown.el patches for markdown-mode.
;;
;; Also unlike most built-in tree-sitter modes, yaml-ts-mode.el's own
;; auto-mode-alist registration is a plain top-level form, not wrapped in an
;; autoload cookie, so it only takes effect once the file has actually been
;; loaded. This layer's :mode keyword registers .yml/.yaml directly instead
;; of waiting on that.
;;
;; ELPA-only: nothing is required from ELPA at all; yaml-ts-mode and eglot
;; are both built in. (yaml-mode, the classic non-tree-sitter mode, is on
;; NonGNU ELPA if indentation support ever becomes a blocker — yaml-ts-mode
;; still has none as of Emacs 31 — but it is not needed here.)
;;
;; You supply the external tool:
;;   - yaml-language-server, from `npm i -g yaml-language-server' — eglot
;;     already knows it
;;   - the yaml tree-sitter grammar — AUTO-INSTALLED on first load (needs git
;;     + a C compiler on PATH)
;;
;; No dape config: YAML is data, not executable code.
;;
;; No `(provide 'yaml)' in the extras file — `yaml' is also the name of a
;; small YAML-parsing library on GNU ELPA; providing it again here would risk
;; a clash with that, the same reasoning extras/json.el follows for `json'.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; =================================================================== yaml.el
(ert-deftest extras-test/given-yaml-then-dot-yml-and-yaml-map-to-yaml-ts-mode ()
  (should (member "\\.ya?ml\\'"
                  (extras-test--use-package-section "yaml.el" 'yaml-ts-mode :mode))))

(ert-deftest extras-test/given-yaml-then-it-gets-the-missing-eglot-hook ()
  "yaml-ts-mode derives from text-mode, so init.el's prog-mode hook never
fires for it; this hooks my-eglot-ensure directly instead."
  (should (member '(yaml-ts-mode . my-eglot-ensure)
                  (extras-test--use-package-section "yaml.el" 'yaml-ts-mode :hook))))

(ert-deftest extras-test/given-yaml-then-the-yaml-grammar-is-registered-and-installed ()
  (should (extras-test--declares
           "yaml.el" '(yaml "https://github.com/tree-sitter/tree-sitter-yaml")))
  (should (extras-test--declares "yaml.el" '(treesit-install-language-grammar 'yaml))))

(provide 'yaml-tests)
;;; yaml-tests.el ends here
