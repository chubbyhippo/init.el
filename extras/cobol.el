;;; cobol.el --- COBOL development extras  -*- lexical-binding: t; -*-

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

(require 'eglot-guard (expand-file-name "extras/eglot-guard" user-emacs-directory))

(use-package cobol-mode
  :ensure t
  :mode ("\\.cob\\'" "\\.cbl\\'" "\\.cpy\\'" "\\.cbx\\'")
  :custom
  (cobol-source-format 'fixed-85))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(cobol-mode . ("superbol-free" "lsp"))))

(my-eglot-guard-until 'cobol-mode "superbol-free")

(provide 'cobol)
