;;; html.el --- HTML / CSS development extras  -*- lexical-binding: t; -*-

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

(use-package css-mode
  :ensure nil
  :init
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(css "https://github.com/tree-sitter/tree-sitter-css"))
    (add-to-list 'treesit-language-source-alist
                 '(html "https://github.com/tree-sitter/tree-sitter-html"))
    (unless (treesit-language-available-p 'css)
      (with-demoted-errors "treesit: %S" (treesit-install-language-grammar 'css)))
    (when (treesit-language-available-p 'css)
      (add-to-list 'major-mode-remap-alist '(css-mode . css-ts-mode))))
  :custom
  (css-indent-offset 2))

(use-package sgml-mode
  :ensure nil
  :hook (html-mode . eglot-ensure)
  :custom
  (sgml-basic-offset 2))
