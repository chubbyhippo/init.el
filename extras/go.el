;;; go.el --- Go development extras  -*- lexical-binding: t; -*-

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

(defun my-go--format-on-save ()
  "Arrange for gopls to gofmt and organize imports before each save."
  (add-hook 'before-save-hook
            (lambda ()
              (when (eglot-managed-p)
                (ignore-errors
                  (eglot-code-action-organize-imports (point-min) (point-max)))
                (eglot-format-buffer)))
            nil t))

(use-package go-ts-mode
  :ensure nil
  :init
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(go "https://github.com/tree-sitter/tree-sitter-go"))
    (add-to-list 'treesit-language-source-alist
                 '(gomod "https://github.com/camdencheek/tree-sitter-go-mod"))
    (dolist (lang '(go gomod))
      (unless (treesit-language-available-p lang)
        (with-demoted-errors "treesit: %S" (treesit-install-language-grammar lang))))
    (when (treesit-language-available-p 'go)
      (add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode)))
    (when (treesit-language-available-p 'gomod)
      (add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))))
  :hook (go-ts-mode . my-go--format-on-save)
  :custom
  (go-ts-mode-indent-offset 4))

(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t))
