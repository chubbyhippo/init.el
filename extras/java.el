;;; java.el --- Java development extras  -*- lexical-binding: t; -*-

;; Optional Java layer for init.el. Disabled by default — uncomment the matching
;; loader at the bottom of init.el to enable it.
;;
;; Most of the stack is built in: the major mode (java-mode, or the tree-sitter
;; java-ts-mode) and eglot, which init.el already hooks onto prog-mode. You
;; supply two external programs:
;;   - jdtls (the Eclipse JDT language server) — eglot launches it automatically
;;     for completion / xref / refactors once jdtls is on PATH
;;   - the vscode-java debug adapter — driven here by dape for breakpoints/stepping
;;
;; Install both with setup-jdtls.sh (repo root): it puts jdtls on PATH and
;; builds the java-debug bundle that the dape wiring below loads into jdtls.
;;
;; ELPA-only: dape and javaimp are on GNU ELPA; the major mode and eglot are
;; built in. (eglot-java / lsp-java are MELPA-only, so they're intentionally
;; not used here.)

;;; Built-in
;; .java opens in the classic cc-mode `java-mode'. If the tree-sitter Java
;; grammar is installed (M-x treesit-install-language-grammar RET java RET),
;; prefer the faster `java-ts-mode'. eglot attaches to either one.
(use-package java-ts-mode
  :ensure nil
  :init
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'java))
    (add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode)))
  :custom
  (java-ts-mode-indent-offset 4))
;;; End Built-in

;;; GNU ELPA
;; DAP-based debugging that pairs with eglot (no lsp-mode needed). To debug:
;; M-x dape, choose the `jdtls' config (it drives the Eclipse JDT debug
;; extension, so jdtls + the java-debug adapter must be installed). Set
;; breakpoints with `dape-breakpoint-toggle'; n / c step once a session stops.
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
;; bundle is loaded through initializationOptions. setup-jdtls.sh builds that
;; jar; this hands it to jdtls. Until the jar exists it's a harmless no-op
;; (`:bundles []') and ordinary LSP still works.
(defvar my/java-debug-bundle-directory
  (expand-file-name "~/.local/share/java-debug/com.microsoft.java.debug.plugin/target/")
  "Directory holding the `com.microsoft.java.debug.plugin-*.jar' from setup-jdtls.sh.")

(defun my/java--jdtls-initialization-options (&optional _server)
  "jdtls initializationOptions that load the java-debug bundle(s)."
  (let ((jars (file-expand-wildcards
               (expand-file-name "com.microsoft.java.debug.plugin-*.jar"
                                 my/java-debug-bundle-directory))))
    `(:bundles ,(vconcat jars)
      :extendedClientCapabilities (:classFileContentsSupport t))))

(with-eval-after-load 'eglot
  ;; prepended, so it wins over eglot's bare ("jdtls") default for these modes
  (add-to-list 'eglot-server-programs
               '((java-mode java-ts-mode)
                 . ("jdtls" :initializationOptions
                    my/java--jdtls-initialization-options))))

(provide 'java)
;;; java.el ends here
