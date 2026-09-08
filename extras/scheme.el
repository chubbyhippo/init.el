;;; scheme.el --- Scheme development extras (Guile, SICP)  -*- lexical-binding: t; -*-

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

(use-package geiser
  :ensure t
  :hook (scheme-mode . geiser-mode)
  :custom
  (geiser-default-implementation 'guile)
  (geiser-active-implementations '(guile chez)))

(use-package geiser-guile
  :ensure t
  :defer t)

(use-package geiser-chez
  :ensure t
  :defer t
  :custom
  (geiser-chez-binary "chezscheme"))

(use-package paredit
  :ensure t
  :hook ((scheme-mode      . enable-paredit-mode)
         (geiser-repl-mode . enable-paredit-mode)))

(when (fboundp 'my-eglot-ensure)
  (advice-add 'my-eglot-ensure :before-while
              (lambda () (not (derived-mode-p 'scheme-mode)))
              '((name . my-scheme--skip-eglot))))
