;;; zig-tests.el --- ERT suite for extras/zig.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/zig.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional Zig layer for init.el. Disabled by default — uncomment the matching
;; loader at the bottom of init.el to enable it.
;;
;; Zig is the odd one out: it has no built-in Emacs mode, so the major mode comes
;; from zig-mode (NonGNU ELPA, installed like any package here). eglot is built
;; in. You supply the external tools:
;;   - the `zig' CLI — for `zig fmt'-on-save and M-x zig-build / zig-run / zig-test
;;   - zls, the Zig language server — eglot launches it once it's on PATH
;;   - LLVM's lldb-dap — used by the dape config registered below (dape ships
;;     no Zig config, so this file registers one)
;;
;; zig-mode formats with `zig fmt' on save out of the box (zig-format-on-save,
;; on by default — set it to nil to disable). That is why there is no
;; format-on-save function of its own to test here, unlike go/rust/elixir.
;;
;; ELPA-only: zig-mode is on NonGNU ELPA, dape on GNU ELPA; eglot is built in.
;;
;; zig-mode auto-binds .zig and derives from prog-mode, so eglot attaches via
;; init.el's prog-mode hook. Eglot already ships a built-in zls entry for
;; zig-mode/zig-ts-mode, so this layer does not need to register one itself.
;;
;; dape ships no Zig config, so one is registered as an lldb-dap config (needs
;; LLVM's lldb-dap). M-x dape → `zig-lldb'; tweak :program to your built
;; binary if it isn't the default `zig-out/bin/main'. Set breakpoints with
;; `dape-breakpoint-toggle'; n / c step once a session stops.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================== zig.el
(ert-deftest extras-test/given-zig-then-zig-mode-is-bound-to-dot-zig ()
  (should (member "\\.zig\\'" (extras-test--use-package-section "zig.el" 'zig-mode :mode))))

(ert-deftest extras-test/given-zig-then-eglot-already-knows-zls-natively ()
  "Eglot's own default table covers zig-mode/zig-ts-mode; extras/zig.el
must not re-register a redundant eglot-server-programs entry."
  (should (require 'eglot))
  (let ((entry (cl-find-if (lambda (e) (member 'zig-mode (ensure-list (car e))))
                           eglot-server-programs)))
    (should entry)
    (should (equal (cdr entry) '("zls"))))
  (should-not (extras-test--declares "zig.el" '(add-to-list 'eglot-server-programs))))

(ert-deftest extras-test/given-zig-then-dape-gets-an-lldb-dap-config ()
  (let ((dape-configs nil))
    (extras-test--eval-with-eval-after-load "zig.el" 'dape)
    (let ((cfg (assoc 'zig-lldb dape-configs)))
      (should cfg)
      (should (equal (plist-get (cdr cfg) :type) "lldb-dap"))
      (should (equal (plist-get (cdr cfg) :program) "zig-out/bin/main")))))

(ert-deftest extras-test/given-zig-then-it-provides-zig ()
  (should (extras-test--declares "zig.el" '(provide 'zig))))

(provide 'zig-tests)
;;; zig-tests.el ends here
