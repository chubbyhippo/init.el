;;; cpp.el --- C / C++ development extras  -*- lexical-binding: t; -*-

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

(use-package c-ts-mode
  :ensure nil
  :init
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(c "https://github.com/tree-sitter/tree-sitter-c"))
    (add-to-list 'treesit-language-source-alist
                 '(cpp "https://github.com/tree-sitter/tree-sitter-cpp"))
    (dolist (lang '(c cpp))
      (unless (treesit-language-available-p lang)
        (with-demoted-errors "treesit: %S" (treesit-install-language-grammar lang))))
    (when (treesit-language-available-p 'c)
      (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode)))
    (when (treesit-language-available-p 'cpp)
      (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode)))
    (when (and (fboundp 'c-or-c++-ts-mode)
               (treesit-language-available-p 'c)
               (treesit-language-available-p 'cpp))
      (add-to-list 'major-mode-remap-alist '(c-or-c++-mode . c-or-c++-ts-mode))))
  :custom
  (c-ts-mode-indent-offset 4))

(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t))
