;;; java-tests.el --- ERT suite for extras/java.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/java.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional Java layer for init.el. Disabled by default — uncomment the matching
;; loader in extras.el to enable it.
;;
;; Most of the stack is built in: the major mode (java-mode, or the tree-sitter
;; java-ts-mode) and eglot, which init.el already hooks onto prog-mode. You
;; supply two external programs:
;;   - jdtls (the Eclipse JDT language server) — eglot launches it automatically
;;     once it's on PATH; it imports Maven/Gradle projects on its own and gives
;;     completion / xref / rename / code actions / formatting — the IntelliJ
;;     core, minus the decompiler view and the test-runner UI
;;   - the java-debug plugin (com.microsoft.java.debug.plugin jar from Maven
;;     Central) — loaded into jdtls so dape's built-in `jdtls' config can set
;;     breakpoints and step
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
;;
;; .java opens in the classic cc-mode `java-mode'. The tree-sitter Java grammar
;; is AUTO-INSTALLED on first load from the source registered in :init (needs
;; git + a C compiler on PATH); once built, `java-ts-mode' is preferred. eglot
;; attaches to either one.
;;
;; Optional, also on GNU ELPA — uncomment if wanted: javaimp, to
;; add/organize Maven/Gradle imports (M-x javaimp-add-import /
;; javaimp-organize-imports).
;;
;; eglot runs `jdtls' from PATH, but the Eclipse server only grows its debug
;; commands (resolveMainClass / startDebugSession / ...) once the java-debug
;; bundle is loaded through initializationOptions. init-el-extras.sh downloads
;; the jar from Maven Central; `my-java--jdtls-initialization-options' hands it
;; to jdtls. Until the jar exists it's a harmless no-op (`:bundles []') and
;; ordinary LSP still works -- see the glob test below. The eglot-server-programs
;; entry is prepended, so it wins over eglot's bare ("jdtls") default for these
;; modes.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================= java.el
(ert-deftest extras-test/given-java-then-java-mode-remaps-to-java-ts-mode ()
  (should (extras-test--declares "java.el" '(java-mode . java-ts-mode)))
  (should (member '(java-ts-mode-indent-offset 4)
                  (extras-test--use-package-section "java.el" 'java-ts-mode :custom))))

(ert-deftest extras-test/given-java-then-yasnippet-hooks-into-both-java-majors ()
  (should (member '((java-mode java-ts-mode) . yas-minor-mode)
                  (extras-test--use-package-section "java.el" 'yasnippet :hook))))

(ert-deftest extras-test/given-java-then-jdtls-initialization-options-glob-the-debug-jar ()
  (extras-test--eval-def "java.el" 'defvar 'my-java-debug-bundle-directory)
  (extras-test--eval-def "java.el" 'defun 'my-java--jdtls-initialization-options)
  (let* ((dir (make-temp-file "java-debug" t))
         (jar (expand-file-name "com.microsoft.java.debug.plugin-1.0.0.jar" dir)))
    (unwind-protect
        (progn
          (write-region "" nil jar)
          (let ((my-java-debug-bundle-directory (file-name-as-directory dir)))
            (let ((opts (my-java--jdtls-initialization-options)))
              (should (equal (append (plist-get opts :bundles) nil) (list jar)))
              (should (equal (plist-get opts :extendedClientCapabilities)
                             '(:classFileContentsSupport t))))))
      (delete-directory dir t))))

(ert-deftest extras-test/given-java-then-eglot-learns-jdtls-with-the-debug-bundle ()
  (extras-test--eval-def "java.el" 'defun 'my-java--jdtls-initialization-options)
  (let ((eglot-server-programs nil))
    (extras-test--eval-with-eval-after-load "java.el" 'eglot)
    (should (equal (cdr (assoc '(java-mode java-ts-mode) eglot-server-programs))
                   '("jdtls" :initializationOptions my-java--jdtls-initialization-options)))))

(ert-deftest extras-test/given-java-then-it-provides-java ()
  (should (extras-test--declares "java.el" '(provide 'java))))

(provide 'java-tests)
;;; java-tests.el ends here
