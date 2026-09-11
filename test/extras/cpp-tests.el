;;; cpp-tests.el --- ERT suite for extras/cpp.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/cpp.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional C/C++ layer for init.el. Disabled by default — uncomment the
;; matching loader in extras.el to enable it. One file covers both
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
;;   - the tree-sitter grammars (c, cpp) — AUTO-INSTALLED on first load from the
;;     sources registered in :init (needs git + a C compiler on PATH); until
;;     they build, C/C++ files open in the classic cc-mode
;;
;; ELPA-only: dape is on GNU ELPA; the major modes and eglot are built in.
;; Formatting is left to clangd / your project's .clang-format (no format-on-
;; save imposed, since C/C++ style is project-specific) — that is why there is
;; no format-on-save test here, unlike go/rust/elixir.
;;
;; Upgrading the cc-mode majors to their tree-sitter equivalents only happens
;; when the grammars are built: .c / .cpp / .h / … already map to c-mode /
;; c++-mode, so remapping via `major-mode-remap-alist' is enough — no
;; auto-mode-alist fiddling. eglot attaches either way. .h files let the
;; content-guessing `c-or-c++-ts-mode' pick C vs C++ (needs both grammars).
;;
;; To debug: M-x dape and pick a config for your debugger — `gdb' (GDB 14.1+,
;; native DAP), `lldb-dap', `lldb-vscode', or `cpptools'; install the matching
;; tool. Set breakpoints with `dape-breakpoint-toggle'; n / c step once a
;; session stops.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================== cpp.el
(ert-deftest extras-test/given-cpp-then-c-and-cpp-remap-to-tree-sitter-modes ()
  (should (extras-test--declares "cpp.el" '(c-mode . c-ts-mode)))
  (should (extras-test--declares "cpp.el" '(c++-mode . c++-ts-mode)))
  (should (extras-test--declares "cpp.el" '(c-or-c++-mode . c-or-c++-ts-mode)))
  (should (member '(c-ts-mode-indent-offset 4)
                  (extras-test--use-package-section "cpp.el" 'c-ts-mode :custom))))

(ert-deftest extras-test/given-cpp-then-dape-is-declared-with-no-language-specific-config ()
  (should (member t (extras-test--use-package-section "cpp.el" 'dape :ensure)))
  (should (member '(dape-buffer-window-arrangement 'right)
                  (extras-test--use-package-section "cpp.el" 'dape :custom))))

(provide 'cpp-tests)
;;; cpp-tests.el ends here
