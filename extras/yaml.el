;;; yaml.el --- YAML development extras  -*- lexical-binding: t; -*-

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

(declare-function my-eglot-ensure "init" ())

(use-package yaml-ts-mode
  :ensure nil
  :mode "\\.ya?ml\\'"
  :hook (yaml-ts-mode . my-eglot-ensure)
  :init
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(yaml "https://github.com/tree-sitter/tree-sitter-yaml"))
    (unless (treesit-language-available-p 'yaml)
      (with-demoted-errors "treesit: %S" (treesit-install-language-grammar 'yaml)))))
