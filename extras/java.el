;;; java.el --- Java development extras  -*- lexical-binding: t; -*-

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

(use-package java-ts-mode
  :ensure nil
  :init
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(java "https://github.com/tree-sitter/tree-sitter-java"))
    (unless (treesit-language-available-p 'java)
      (with-demoted-errors "treesit: %S" (treesit-install-language-grammar 'java)))
    (when (treesit-language-available-p 'java)
      (add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode))))
  :custom
  (java-ts-mode-indent-offset 4))

(use-package yasnippet
  :ensure t
  :hook ((java-mode java-ts-mode) . yas-minor-mode))

(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)
  (dape-inlay-hints t))

(defvar my-java-debug-bundle-directory
  (expand-file-name "~/.local/share/java-debug/")
  "Directory holding the `com.microsoft.java.debug.plugin-*.jar' bundle.")

(defun my-java--jdtls-initialization-options (&optional _server)
  "jdtls initializationOptions that load the java-debug bundle(s)."
  (let ((jars (file-expand-wildcards
               (expand-file-name "com.microsoft.java.debug.plugin-*.jar"
                                 my-java-debug-bundle-directory))))
    `(:bundles ,(vconcat jars)
      :extendedClientCapabilities (:classFileContentsSupport t))))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((java-mode java-ts-mode)
                 . ("jdtls" :initializationOptions
                    my-java--jdtls-initialization-options))))

(my-eglot-guard-until 'java-mode "jdtls")

(provide 'java)
