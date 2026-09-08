;;; elixir.el --- Elixir development extras  -*- lexical-binding: t; -*-

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

(defun my-elixir--format-on-save ()
  "Arrange for the language server to format the buffer before each save."
  (add-hook 'before-save-hook
            (lambda () (when (eglot-managed-p) (eglot-format-buffer)))
            nil t))

(use-package elixir-ts-mode
  :ensure nil
  :init
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(elixir "https://github.com/elixir-lang/tree-sitter-elixir"))
    (add-to-list 'treesit-language-source-alist
                 '(heex "https://github.com/phoenixframework/tree-sitter-heex"))
    (dolist (lang '(elixir heex))
      (unless (treesit-language-available-p lang)
        (with-demoted-errors "treesit: %S" (treesit-install-language-grammar lang))))
    (when (treesit-language-available-p 'elixir)
      (add-to-list 'auto-mode-alist '("\\.exs?\\'" . elixir-ts-mode)))
    (when (treesit-language-available-p 'heex)
      (add-to-list 'auto-mode-alist '("\\.heex\\'" . heex-ts-mode))))
  :hook (elixir-ts-mode . my-elixir--format-on-save))

(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t)
  :config
  (add-to-list 'dape-configs
               `(elixir-ls
                 modes (elixir-ts-mode elixir-mode)
                 ensure dape-ensure-command
                 command "debug_adapter.sh"
                 command-cwd dape-command-cwd
                 :type "mix_task"
                 :request "launch"
                 :task "test"
                 :taskArgs ["--trace"]
                 :projectDir dape-command-cwd
                 :requireFiles ["test/**/test_helper.exs"
                                "test/**/*_test.exs"])))

(provide 'elixir)
