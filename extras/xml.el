;;; xml.el --- XML development extras  -*- lexical-binding: t; -*-

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

(require 'eglot-ensure (expand-file-name "extras/eglot-ensure" user-emacs-directory))

(declare-function my-eglot-ensure "init" ())

(use-package nxml-mode
  :ensure nil
  :hook (nxml-mode . my-eglot-ensure))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(nxml-mode . ("lemminx"))))

(my-eglot-ensure-once-ready 'nxml-mode "lemminx")

(provide 'xml)
