;;; typescript.el --- JavaScript / TypeScript development extras  -*- lexical-binding: t; -*-

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

(defun my-typescript--npm-bin (name &optional dir)
  "Return the project-local node_modules/.bin/NAME under DIR, else NAME."
  (if-let* ((root (locate-dominating-file (or dir default-directory) "node_modules"))
            (bin (expand-file-name (concat "node_modules/.bin/" name) root))
            ((file-executable-p bin)))
      bin
    name))

(defun my-typescript--lsp-contact (&optional _interactive project)
  "Contact function preferring a project-local typescript-language-server."
  (list (my-typescript--npm-bin "typescript-language-server"
                                 (and project (project-root project)))
        "--stdio"))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(((js-mode :language-id "javascript")
                  (js-ts-mode :language-id "javascript")
                  (tsx-ts-mode :language-id "typescriptreact")
                  (typescript-ts-mode :language-id "typescript")
                  (typescript-mode :language-id "typescript"))
                 . my-typescript--lsp-contact)))

(defun my-typescript--lsp-ready-p ()
  "Non-nil once typescript-language-server (project-local or on PATH) is
available."
  (let ((bin (my-typescript--npm-bin "typescript-language-server")))
    (or (file-name-absolute-p bin) (executable-find bin))))

(my-eglot-guard-until '(js-mode typescript-mode tsx-mode) #'my-typescript--lsp-ready-p)

(defun my-typescript-eslint-check ()
  "Run ESLint on the current file in a `compile' buffer."
  (interactive)
  (compile (format "%s %s" (my-typescript--npm-bin "eslint")
                    (shell-quote-argument buffer-file-name))))

(defun my-typescript--project-package-json (&optional dir)
  "Parse the nearest package.json above DIR (or `default-directory') --
nil if there is none, or it fails to parse."
  (when-let* ((root (locate-dominating-file (or dir default-directory) "package.json")))
    (with-temp-buffer
      (insert-file-contents (expand-file-name "package.json" root))
      (ignore-errors
        (if (fboundp 'json-parse-buffer)
            (json-parse-buffer :object-type 'alist :array-type 'list)
          (require 'json)
          (goto-char (point-min))
          (json-read))))))

(defun my-typescript--project-has-dep-p (dep &optional dir)
  "Non-nil if DEP (a symbol) is a dependency or devDependency of the project
containing DIR (or `default-directory')."
  (when-let* ((pkg (my-typescript--project-package-json dir)))
    (or (alist-get dep (alist-get 'dependencies pkg))
        (alist-get dep (alist-get 'devDependencies pkg)))))

(defun my-typescript-run-dev-server ()
  "Start this project's Expo or React Native dev server, whichever its
package.json declares -- Expo takes priority, since an Expo project also
depends on react-native transitively.  Runs in a comint-backed `compile'
buffer so Metro's interactive keys (r/a/i/m/...) still work."
  (interactive)
  (cond
   ((my-typescript--project-has-dep-p 'expo)
    (compile (format "%s start" (my-typescript--npm-bin "expo")) t))
   ((my-typescript--project-has-dep-p 'react-native)
    (compile (format "%s start" (my-typescript--npm-bin "react-native")) t))
   (t (user-error "Neither react-native nor expo found in this project's package.json"))))

(use-package js
  :ensure nil
  :bind (:map js-ts-mode-map ("C-c C-l" . my-typescript-eslint-check)
              ("C-c C-s" . my-typescript-run-dev-server))
  :hook (js-ts-mode . prettier-format-on-save-mode)
  :init
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(javascript "https://github.com/tree-sitter/tree-sitter-javascript"))
    (unless (treesit-language-available-p 'javascript)
      (with-demoted-errors "treesit: %S" (treesit-install-language-grammar 'javascript)))
    (when (treesit-language-available-p 'javascript)
      (dolist (m '(js-mode javascript-mode js-jsx-mode jsx-mode))
        (add-to-list 'major-mode-remap-alist (cons m 'js-ts-mode)))
      (add-to-list 'auto-mode-alist '("\\.jsx\\'" . js-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.m?js\\'" . js-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.cjs\\'" . js-ts-mode))))
  :custom
  (js-indent-level 2))

(use-package typescript-ts-mode
  :ensure nil
  :init
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(typescript "https://github.com/tree-sitter/tree-sitter-typescript"
                              nil "typescript/src"))
    (add-to-list 'treesit-language-source-alist
                 '(tsx "https://github.com/tree-sitter/tree-sitter-typescript"
                       nil "tsx/src"))
    (dolist (lang '(typescript tsx))
      (unless (treesit-language-available-p lang)
        (with-demoted-errors "treesit: %S" (treesit-install-language-grammar lang))))
    (when (treesit-language-available-p 'typescript)
      (add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.mts\\'" . typescript-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.cts\\'" . typescript-ts-mode)))
    (when (treesit-language-available-p 'tsx)
      (add-to-list 'major-mode-remap-alist '(tsx-mode . tsx-ts-mode))
      (add-to-list 'major-mode-remap-alist '(typescript-tsx-mode . tsx-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))))
  :bind (:map typescript-ts-mode-map ("C-c C-l" . my-typescript-eslint-check)
              ("C-c C-s" . my-typescript-run-dev-server)
         :map tsx-ts-mode-map ("C-c C-l" . my-typescript-eslint-check)
              ("C-c C-s" . my-typescript-run-dev-server))
  :hook ((typescript-ts-mode tsx-ts-mode) . prettier-format-on-save-mode)
  :custom
  (typescript-ts-mode-indent-offset 2))

(use-package reformatter
  :ensure t
  :config
  (reformatter-define prettier-format
    :program (my-typescript--npm-bin "prettier")
    :args (list "--stdin-filepath" buffer-file-name)
    :lighter " Prettier"))

(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t)
  :config
  (dolist (key '(js-debug-tsx js-debug-ts-node))
    (when-let* ((cfg (alist-get key dape-configs))
                (runtime (plist-get cfg :runtimeExecutable)))
      (plist-put cfg :runtimeExecutable
                 `(my-typescript--npm-bin ,runtime (dape-cwd))))))

(provide 'typescript)
