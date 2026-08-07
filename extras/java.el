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

;; Optional Java layer for init.el. Disabled by default — uncomment the matching
;; loader at the bottom of init.el to enable it.
;;
;; Most of the stack is built in: the major mode (java-mode, or the tree-sitter
;; java-ts-mode) and eglot, which init.el already hooks onto prog-mode. You
;; supply two external programs:
;;   - jdtls (the Eclipse JDT language server) — eglot launches it automatically
;;     once it's on PATH; it imports Maven/Gradle projects on its own and gives
;;     completion / xref / rename / code actions / formatting — the IntelliJ
;;     core, minus the decompiler view and the test-runner UI
;;   - the java-debug plugin (com.microsoft.java.debug.plugin jar from Maven
;;     Central) — loaded into jdtls below so dape's built-in `jdtls' config can
;;     set breakpoints and step
;;
;; Both are installed by wsl-ubuntu-settings' init-el-extras.sh: jdtls into
;; ~/.local/share/jdtls (linked at ~/.local/bin/jdtls), the debug jar into
;; ~/.local/share/java-debug/.
;;
;; ELPA-only: dape, yasnippet, and javaimp are on GNU ELPA; the major mode and
;; eglot are built in. (eglot-java / lsp-java are MELPA-only, so they're
;; intentionally not used here.)
;;
;; yasnippet here only expands jdtls' LSP completion snippets — no ported
;; templates are bundled.

;;; Built-in
;; .java opens in the classic cc-mode `java-mode'. The tree-sitter Java grammar
;; is AUTO-INSTALLED on first load from the source registered in :init (needs
;; git + a C compiler on PATH); once built, `java-ts-mode' is preferred. eglot
;; attaches to either one.
(use-package java-ts-mode
  :ensure nil
  :init
  ;; Register the grammar source (no URL prompt on install); prefer java-ts-mode
  ;; once the grammar exists.
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(java "https://github.com/tree-sitter/tree-sitter-java"))
    ;; auto-install the grammar on first load (needs git + a C compiler).
    (unless (treesit-language-available-p 'java)
      (with-demoted-errors "treesit: %S" (treesit-install-language-grammar 'java)))
    (when (treesit-language-available-p 'java)
      (add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode))))
  :custom
  (java-ts-mode-indent-offset 4))
;;; End Built-in

;;; GNU ELPA
;; with yas-minor-mode on, eglot expands jdtls' completion snippets — a
;; method's args drop in as TAB-able placeholders.
(use-package yasnippet
  :ensure t
  :hook ((java-mode java-ts-mode) . yas-minor-mode))

;; DAP-based debugging that pairs with eglot (no lsp-mode needed). To debug:
;; M-x dape, choose the `jdtls' config — it asks the running eglot jdtls
;; session to start a debug session, which only works once the java-debug
;; bundle below is loaded. Set breakpoints with `dape-breakpoint-toggle';
;; n / c step once a session stops.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped

;; Optional, also on GNU ELPA — uncomment if wanted:
;; (use-package javaimp :ensure t) ; add/organize Maven/Gradle imports
;;                                 ; M-x javaimp-add-import / javaimp-organize-imports
;;; End GNU ELPA

;;; Debug adapter (java-debug) — makes `M-x dape' => `jdtls' actually work
;; eglot runs `jdtls' from PATH, but the Eclipse server only grows its debug
;; commands (resolveMainClass / startDebugSession / ...) once the java-debug
;; bundle is loaded through initializationOptions. init-el-extras.sh downloads
;; the jar from Maven Central; this hands it to jdtls. Until the jar exists
;; it's a harmless no-op (`:bundles []') and ordinary LSP still works.
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
  ;; prepended, so it wins over eglot's bare ("jdtls") default for these modes
  (add-to-list 'eglot-server-programs
               '((java-mode java-ts-mode)
                 . ("jdtls" :initializationOptions
                    my-java--jdtls-initialization-options))))

(provide 'java)
;;; java.el ends here
