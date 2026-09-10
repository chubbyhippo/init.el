;;; php-tests.el --- ERT suite for extras/php.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/php.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional PHP layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. Handles .php.
;;
;; php-ts-mode is built into Emacs core, but only since Emacs 30 (it did not
;; exist in 29) -- there is no classic, non-tree-sitter php-mode in core at
;; all. eglot is built in too. Both are otherwise handled the way go.el /
;; ruby.el handle their tree-sitter modes: php-ts-mode derives from
;; prog-mode, so init.el's global prog-mode hook reaches it with no extra
;; work here, and eglot's own table already maps php-ts-mode (and the
;; classic php-mode/phps-mode) to phpactor, falling back to the
;; felixfbecker PHP language server -- nothing to register for that here.
;;
;; php-ts-mode.el's own auto-mode-alist registration for .php is a plain
;; top-level form, not wrapped in an autoload cookie, so it only takes
;; effect once the file has actually been loaded -- the same gap json.el and
;; yaml.el hit for their own tree-sitter modes. This layer's :mode keyword
;; registers .php directly instead of waiting on that.
;;
;; ELPA-only: dape is on GNU ELPA; php-ts-mode and eglot are built in.
;; (the classic php-mode package is NonGNU ELPA-only and not needed here.)
;;
;; You supply the external tools:
;;   - phpactor (https://github.com/phpactor/phpactor) — eglot launches it
;;     automatically for completion / xref / refactors once it's on PATH
;;   - Xdebug, with the vscode-php-debug adapter dape already ships a config
;;     for (`xdebug', covering php-mode and php-ts-mode) — M-x dape to use it
;;   - the php tree-sitter grammar — AUTO-INSTALLED on first load from the
;;     source registered in :init (needs git + a C compiler on PATH; pinned
;;     to v0.23.11 and the php/src subdirectory, matching what Emacs core's
;;     own php-ts-mode.el recommends)
;;
;; No `(provide 'php)' in the extras file -- php-ts-mode.el itself already
;; provides `php-ts-mode', not the bare `php' name, but this layer is loaded
;; by path from init.el like every other extras file, so a provide is not
;; needed for it to work.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ==================================================================== php.el
(ert-deftest extras-test/given-php-then-dot-php-maps-to-php-ts-mode ()
  (should (member "\\.php\\'"
                  (extras-test--use-package-section "php.el" 'php-ts-mode :mode))))

(ert-deftest extras-test/given-php-then-the-php-grammar-is-registered-and-installed ()
  (should (extras-test--declares
           "php.el" '(php "https://github.com/tree-sitter/tree-sitter-php"
                          "v0.23.11" "php/src")))
  (should (extras-test--declares "php.el" '(treesit-install-language-grammar 'php))))

(ert-deftest extras-test/given-php-then-dape-is-declared-with-no-language-specific-config ()
  "dape already ships an xdebug config for php-mode/php-ts-mode, so this
layer only needs to declare dape -- no config to register."
  (should (member t (extras-test--use-package-section "php.el" 'dape :ensure)))
  (should (member '(dape-buffer-window-arrangement 'right)
                  (extras-test--use-package-section "php.el" 'dape :custom))))

(provide 'php-tests)
;;; php-tests.el ends here
