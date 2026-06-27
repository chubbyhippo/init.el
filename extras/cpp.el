;;; cpp.el --- C / C++ development extras  -*- lexical-binding: t; -*-

;; Optional C/C++ layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. One file covers both
;; languages: they share a language server, a debug adapter, headers, and build
;; tooling, so splitting them would only duplicate config. Handles
;; .c / .h and .cpp / .cc / .hpp / … .
;;
;; Most of the stack is built in: the tree-sitter major modes (c-ts-mode,
;; c++-ts-mode) and eglot, which init.el already hooks onto prog-mode. You
;; supply the external tools:
;;   - clangd — eglot launches it automatically for every C/C++ buffer once it's
;;     on PATH; the one server handles both, reading compile_commands.json
;;   - a native debugger for dape — GDB 14.1+ (native DAP), LLVM's lldb-dap, or
;;     the cpptools adapter — for breakpoints/stepping
;;   - the tree-sitter grammars (M-x treesit-install-language-grammar RET c,
;;     then again for cpp) — until then C/C++ files open in the classic cc-mode
;;
;; ELPA-only: dape is on GNU ELPA; the major modes and eglot are built in.
;; Formatting is left to clangd / your project's .clang-format (no format-on-
;; save imposed, since C/C++ style is project-specific).

;;; Built-in
;; Upgrade the cc-mode majors to their tree-sitter equivalents when the grammars
;; are built. .c / .cpp / .h / … already map to c-mode / c++-mode, so remapping
;; is enough — no auto-mode-alist fiddling. eglot attaches either way.
(use-package c-ts-mode
  :ensure nil
  :init
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'c))
    (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode)))
  (when (and (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'cpp))
    (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode)))
  ;; .h files: let the content-guessing mode pick C vs C++ (needs both grammars)
  (when (and (fboundp 'c-or-c++-ts-mode)
             (fboundp 'treesit-language-available-p)
             (treesit-language-available-p 'c)
             (treesit-language-available-p 'cpp))
    (add-to-list 'major-mode-remap-alist '(c-or-c++-mode . c-or-c++-ts-mode)))
  :custom
  (c-ts-mode-indent-offset 4))
;;; End Built-in

;;; GNU ELPA
;; DAP-based debugging that pairs with eglot (no lsp-mode needed). To debug:
;; M-x dape and pick a config for your debugger — `gdb' (GDB 14.1+, native DAP),
;; `lldb-dap', `lldb-vscode', or `cpptools'; install the matching tool. Set
;; breakpoints with `dape-breakpoint-toggle'; n / c step once a session stops.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped
;;; End GNU ELPA

;; No `(provide 'cpp)' — Emacs already ships a built-in cpp.el (C-preprocessor
;; highlighting) that owns the `cpp' feature; this file is loaded by path from
;; init.el, so a provide isn't needed.
;;; cpp.el ends here
