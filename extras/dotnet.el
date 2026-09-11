;;; dotnet.el --- C# / .NET development extras  -*- lexical-binding: t; -*-

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

(use-package csharp-mode
  :ensure nil
  :mode "\\.csx\\'")

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((csharp-mode csharp-ts-mode) . ("csharp-ls"))))

(when (fboundp 'my-eglot-ensure)
  (advice-add 'my-eglot-ensure :before-while
              (lambda () (or (not (derived-mode-p 'csharp-mode))
                             (executable-find "csharp-ls")))
              '((name . my-dotnet--skip-eglot-until-csharp-ls))))

(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t))

(provide 'dotnet)
