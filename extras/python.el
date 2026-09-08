;;; python.el --- Python development extras  -*- lexical-binding: t; -*-

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

(use-package python
  :ensure nil
  :init
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(python "https://github.com/tree-sitter/tree-sitter-python"))
    (unless (treesit-language-available-p 'python)
      (with-demoted-errors "treesit: %S" (treesit-install-language-grammar 'python)))
    (when (treesit-language-available-p 'python)
      (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))))
  :custom
  (python-indent-guess-indent-offset-verbose nil))

(use-package buffer-env
  :ensure t
  :hook ((hack-local-variables . buffer-env-update)
         (comint-mode          . buffer-env-update))
  :custom
  (buffer-env-script-name '(".envrc"
                            ".venv/bin/activate"
                            ".venv/Scripts/activate.bat"))
  :config
  (add-to-list 'buffer-env-command-alist
               '("/bin/activate\\'" . "set -a && . \"$0\" && env -0"))
  (add-to-list 'buffer-env-command-alist
               '("/Scripts/activate\\.bat\\'" . "call \"$0\" >NUL && set")))

(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t))
