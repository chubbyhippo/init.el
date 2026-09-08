;;; rust-tests.el --- ERT suite for extras/rust.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/rust.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional Rust layer for init.el. Disabled by default — uncomment the matching
;; loader at the bottom of init.el to enable it.
;;
;; Most of the stack is built in: the tree-sitter major mode (rust-ts-mode) and
;; eglot, which init.el already hooks onto prog-mode. You supply the external
;; tools:
;;   - rust-analyzer (rustup component add rust-analyzer) — eglot launches it
;;     automatically for completion / xref / refactors / formatting once it's
;;     on PATH
;;   - LLVM's lldb-dap (or lldb-vscode) — driven here by dape for
;;     breakpoints/stepping
;;   - the tree-sitter grammar (rust) — AUTO-INSTALLED on first load from the
;;     source registered in :init (needs git + a C compiler on PATH); until it
;;     builds, .rs isn't auto-detected
;;
;; ELPA-only: dape is on GNU ELPA; the major mode and eglot are built in.
;; (rust-mode / rustic are MELPA-only, so they're not used here.) Cargo commands
;; run through M-x project-compile / compile.
;;
;; rustfmt runs on save, via rust-analyzer — but only fires when eglot is
;; actually managing the buffer; see the format-on-save test below.
;;
;; To debug: M-x dape, choose `lldb-dap' (or `lldb-vscode') — it debugs the
;; built binary via LLDB, so the LLVM lldb tools must be installed. Set
;; breakpoints with `dape-breakpoint-toggle'; n / c step once a session stops.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================= rust.el
(ert-deftest extras-test/given-rust-then-format-on-save-only-formats-when-eglot-manages-it ()
  (extras-test--eval-def "rust.el" 'defun 'my-rust--format-on-save)
  (let ((fn (extras-test--capture-before-save-hook-fn #'my-rust--format-on-save)))
    (let (called)
      (cl-letf (((symbol-function 'eglot-managed-p) (lambda () nil))
                ((symbol-function 'eglot-format-buffer) (lambda (&rest _) (setq called t))))
        (funcall fn))
      (should-not called))
    (let (called)
      (cl-letf (((symbol-function 'eglot-managed-p) (lambda () t))
                ((symbol-function 'eglot-format-buffer) (lambda (&rest _) (setq called t))))
        (funcall fn))
      (should called))))

(ert-deftest extras-test/given-rust-then-rs-files-map-to-rust-ts-mode ()
  (should (extras-test--declares "rust.el" '("\\.rs\\'" . rust-ts-mode)))
  (should (member '(rust-ts-mode-indent-offset 4)
                  (extras-test--use-package-section "rust.el" 'rust-ts-mode :custom))))

(ert-deftest extras-test/given-rust-then-it-provides-rust ()
  (should (extras-test--declares "rust.el" '(provide 'rust))))

(provide 'rust-tests)
;;; rust-tests.el ends here
