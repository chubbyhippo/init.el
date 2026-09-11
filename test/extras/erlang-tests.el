;;; erlang-tests.el --- ERT suite for extras/erlang.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/erlang.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional Erlang layer for init.el. Disabled by default — uncomment the
;; matching loader in extras.el to enable it.
;;
;; Erlang is the odd one out. There is no built-in tree-sitter mode for it, and
;; the canonical `erlang-mode' (erlang.el) is NOT on GNU/NonGNU ELPA — it ships
;; INSIDE Erlang/OTP, under `<otp>/lib/tools-<ver>/emacs/'. (The MELPA `erlang'
;; package is that same file, but this config never uses MELPA.) So this layer
;; puts OTP's own emacs/ directory on `load-path' and loads that erlang.el. You
;; supply the external tools:
;;   - Erlang/OTP — provides `erl' and the bundled erlang.el / erlang-mode
;;   - erlang_ls — put it on PATH and eglot launches it automatically (eglot's
;;     built-in Erlang entry runs `erlang_ls --transport stdio') for
;;     completion / xref / hovers
;;
;; No tree-sitter grammar step (there is no erlang-ts-mode). No dape wiring:
;; Erlang has no standard DAP adapter — debug with OTP's own tools instead
;; (`debugger:start().' for the GUI, or `int:i/1' + `int:break/2' from a shell).
;; Rebar3 / erlang.mk builds run through M-x project-compile.
;;
;; `my-erlang--otp-emacs-dir' asks `erl' for the `tools' application lib dir
;; and appends emacs/, since that is where OTP's bundled erlang.el lives.
;; Loading tries `load-path' first (site config / a hardcoded entry), else
;; asks `erl' where OTP keeps it. The file that carries this logic does NOT
;; `(provide 'erlang)', so `(require 'erlang)' there always resolves to OTP's
;; copy, never to that file. If auto-detect misses (unusual OTP layout), you
;; can hardcode it: (add-to-list 'load-path "/path/to/otp/lib/tools-<ver>/emacs")
;;
;; eglot auto-starts from init.el's prog-mode hook (modern erlang-mode derives
;; from prog-mode). On an older erlang.el that doesn't, add:
;;   (add-hook 'erlang-mode-hook #'eglot-ensure)
;;
;; No `(provide 'erlang)' in the extras file itself — the feature/library name
;; `erlang' belongs to OTP's own erlang.el; that file is loaded by path, so
;; providing it would shadow the real one. (Same reason cpp.el / python.el /
;; go.el skip their provides.)

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================ erlang.el
(ert-deftest extras-test/given-erlang-then-otp-emacs-dir-is-nil-without-erl-on-path ()
  (extras-test--eval-def "erlang.el" 'defun 'my-erlang--otp-emacs-dir)
  (cl-letf (((symbol-function 'executable-find) (lambda (_) nil)))
    (should-not (my-erlang--otp-emacs-dir))))

(ert-deftest extras-test/given-erlang-then-otp-emacs-dir-is-nil-when-the-path-does-not-exist ()
  (extras-test--eval-def "erlang.el" 'defun 'my-erlang--otp-emacs-dir)
  (cl-letf (((symbol-function 'executable-find) (lambda (_) "/usr/bin/erl"))
            ((symbol-function 'shell-command-to-string)
             (lambda (_) "/definitely/not/a/real/path/xyz")))
    (should-not (my-erlang--otp-emacs-dir))))

(ert-deftest extras-test/given-erlang-then-otp-emacs-dir-resolves-a-real-directory ()
  (extras-test--eval-def "erlang.el" 'defun 'my-erlang--otp-emacs-dir)
  (let ((dir (directory-file-name temporary-file-directory)))
    (cl-letf (((symbol-function 'executable-find) (lambda (_) "/usr/bin/erl"))
              ((symbol-function 'shell-command-to-string) (lambda (_) dir)))
      (should (equal (my-erlang--otp-emacs-dir) dir)))))

(ert-deftest extras-test/given-erlang-then-its-file-extensions-map-to-erlang-mode ()
  (should (extras-test--declares "erlang.el" '("\\.erl\\'" . erlang-mode)))
  (should (extras-test--declares "erlang.el" '("\\.hrl\\'" . erlang-mode)))
  (should (extras-test--declares "erlang.el" '("/rebar\\.config\\'" . erlang-mode))))

(provide 'erlang-tests)
;;; erlang-tests.el ends here
