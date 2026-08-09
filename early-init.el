;;; early-init.el --- startup hygiene  -*- lexical-binding: t; -*-

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

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Skip file-name handlers (tramp, compression, …) while starting up; init.el
;; restores the saved alist on emacs-startup-hook.
(defvar my--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(setq frame-inhibit-implied-resize t)

(when (eq system-type 'windows-nt)
  (setq w32-get-true-file-attributes nil
        w32-pipe-read-delay 0
        w32-pipe-buffer-size (* 64 1024))
  (setq inhibit-compacting-font-caches t))

(setq load-prefer-newer t)

(setq inhibit-x-resources t)

(setq inhibit-startup-screen t)
(fset 'display-startup-echo-area-message #'ignore)

(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)

(setq native-comp-async-report-warnings-errors 'silent
      package-native-compile t)

;; Explicit policy: GNU + NonGNU only — never MELPA (or any third archive).
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
