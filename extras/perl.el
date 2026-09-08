;;; perl.el --- Perl development extras  -*- lexical-binding: t; -*-

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

(use-package cperl-mode
  :ensure nil
  :init
  (add-to-list 'major-mode-remap-alist '(perl-mode . cperl-mode))
  :custom
  (cperl-indent-level 4)
  (cperl-continued-statement-offset 4)
  (cperl-close-paren-offset -4)
  (cperl-indent-parens-as-block t)
  (cperl-tab-always-indent t)
  (cperl-invalid-face nil))

(provide 'perl)
