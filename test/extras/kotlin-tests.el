;;; kotlin-tests.el --- ERT suite for extras/kotlin.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/kotlin.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional Kotlin layer for init.el. Disabled by default -- uncomment the
;; matching loader in extras.el to enable it.
;;
;; kotlin-mode is on NonGNU ELPA (Emacs-Kotlin-Mode-Maintainers/kotlin-mode),
;; not GNU ELPA or MELPA, so it fits this config's "never MELPA" rule.
;; `M-x package-install kotlin-mode' pulls it once NonGNU ELPA is enabled
;; (early-init.el already lists it). Unlike cobol.el's ELPA mode, kotlin-mode
;; registers its OWN auto-mode-alist entry (.kt and .kts) behind an
;; autoload cookie, so no explicit :mode is needed here -- same shape as
;; sql.el leaning on sql-mode's own default association.
;;
;; There is NO tree-sitter path -- same "not a yet" situation as cobol.el and
;; sql.el. fwcd/tree-sitter-kotlin exists upstream, but no consuming
;; kotlin-ts-mode ships in Emacs core or lives on GNU/NonGNU ELPA, only
;; GitHub-only wrappers this config's ELPA-only rule excludes.
;;
;; You supply the external tool: kotlin-lsp (github.com/Kotlin/kotlin-lsp),
;; JetBrains' official IntelliJ-based language server -- Alpha, and its
;; predecessor fwcd/kotlin-language-server now points to it as the
;; replacement ("this project can be considered deprecated"). Install via
;; `brew install JetBrains/utils/kotlin-lsp' (symlinks a `kotlin-lsp'
;; executable onto PATH) or by downloading the standalone archive and
;; symlinking `bin/intellij-server' to `kotlin-lsp' yourself; JetBrains'
;; own scripts/lsp-kotlin-emacs-eglot.el recipe is the source for the
;; `--stdio' flag and the eglot-server-programs shape below.
;;
;; WHY THE eglot HOOK IS GUARDED. kotlin-mode derives from prog-mode, so
;; init.el's global `my-eglot-ensure' fires in every Kotlin buffer; without
;; a guard that means "Searching for program: ... kotlin-lsp" in
;; *Warnings* on every .kt/.kts file until the server is actually
;; installed. Same shape of advice as cobol.el and sql.el (skip until the
;; binary exists).
;;
;; NO debug adapter. dape ships no Kotlin/JVM config (checked its
;; dape-configs alist). fwcd/kotlin-debug-adapter exists standalone and
;; dap-mode has a dap-kotlin integration for it, but dap-mode is a
;; different, heavier package this config does not use -- wiring
;; kotlin-debug-adapter into dape would mean hand-writing a dape-configs
;; entry yourself. Same gap as cobol/erlang/haskell.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; =============================================================== kotlin.el
(ert-deftest extras-test/given-kotlin-then-kotlin-mode-is-used-unmodified ()
  "kotlin-mode is an ELPA package (:ensure t) that registers its own .kt/.kts
auto-mode-alist entries via an autoload cookie, so no :mode/:hook/:custom
is needed here."
  (should (extras-test--declares "kotlin.el" '(use-package kotlin-mode :ensure t))))

(ert-deftest extras-test/given-kotlin-then-eglot-learns-kotlin-lsp ()
  (let ((eglot-server-programs nil))
    (extras-test--eval-with-eval-after-load "kotlin.el" 'eglot)
    (should (equal (cdr (assoc 'kotlin-mode eglot-server-programs))
                   '("kotlin-lsp" "--stdio")))))

(ert-deftest extras-test/given-kotlin-then-eglot-is-skipped-until-kotlin-lsp-exists ()
  "The advice on my-eglot-ensure should hold eglot back in kotlin-mode buffers
until kotlin-lsp is on PATH, and never touch other modes."
  (defun my-eglot-ensure () 'ran)
  (unwind-protect
      (progn
        (extras-test--eval-def "kotlin.el" 'when '(fboundp 'my-eglot-ensure))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest _) t))
                  ((symbol-function 'executable-find) (lambda (_) nil)))
          (should-not (my-eglot-ensure)))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest _) t))
                  ((symbol-function 'executable-find) (lambda (_) "/usr/local/bin/kotlin-lsp")))
          (should (eq (my-eglot-ensure) 'ran)))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest _) nil)))
          (should (eq (my-eglot-ensure) 'ran))))
    (advice-remove 'my-eglot-ensure 'my-kotlin--skip-eglot-until-kotlin-lsp)
    (fmakunbound 'my-eglot-ensure)))

(ert-deftest extras-test/given-kotlin-then-it-provides-kotlin ()
  (should (extras-test--declares "kotlin.el" '(provide 'kotlin))))

(provide 'kotlin-tests)
;;; kotlin-tests.el ends here
