;;; clojure-tests.el --- ERT suite for extras/clojure.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/clojure.el (moved here when that file's
;; comments were stripped, so the rationale below still documents the tests
;; that pin its behavior down):
;;
;; Optional Clojure layer for init.el. Disabled by default — uncomment the
;; matching loader in extras.el to enable it. Every package here is
;; on NonGNU ELPA, so it installs through the same `package' / `use-package'
;; setup as the rest of the config (no MELPA needed).
;;
;;   clojure-mode  major mode + indentation (paredit gives structural editing)
;;   cider         REPL, interactive eval, inspector, test runner, and the
;;                 step debugger — this is the "develop / debug Clojure" piece
;;   paredit       keep the parens balanced while you edit
;;
;; eglot already auto-starts on prog-mode (see init.el), so opening a .clj file
;; will try to launch clojure-lsp for static analysis/xref alongside CIDER's
;; REPL — install the clojure-lsp binary separately if you want that. CIDER on
;; its own needs only a JVM + a project (deps.edn / project.clj / shadow-cljs).
;;
;; clojure-mode: tree-sitter alternative -- replace it with `clojure-ts-mode'
;; (also on NonGNU ELPA), then `M-x treesit-install-language-grammar clojure'.
;; If you switch, change the clojure-mode hooks below to clojure-ts-mode too.
;;
;; cider: start a REPL with C-c M-j (cider-jack-in). Then: C-c C-k load the
;; file · C-c C-e eval the form before point · C-c C-z hop to the REPL.
;; Debugger: put point in a defn, hit C-u C-M-x to instrument it, run it, then
;; step with n (next) / c (continue) / q (quit).
;;
;; Also on NonGNU ELPA if you want them — uncomment to enable:
;;   flymake-kondor  clj-kondo linting via flymake (needs the clj-kondo
;;                   binary; redundant if you let eglot drive clojure-lsp)
;;   inf-clojure     bare-bones REPL, a lighter alternative to CIDER

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ============================================================== clojure.el
(ert-deftest extras-test/given-clojure-then-clojure-mode-cider-and-paredit-are-declared ()
  (should (extras-test--declares "clojure.el" '(use-package clojure-mode :ensure t)))
  (should (member '(clojure-mode . cider-mode)
                  (extras-test--use-package-section "clojure.el" 'cider :hook)))
  (should (member '(cider-repl-display-help-banner nil)
                  (extras-test--use-package-section "clojure.el" 'cider :custom)))
  (should (member '((clojure-mode    . enable-paredit-mode)
                    (cider-repl-mode . enable-paredit-mode))
                  (extras-test--use-package-section "clojure.el" 'paredit :hook))))

(ert-deftest extras-test/given-clojure-then-it-provides-clojure ()
  (should (extras-test--declares "clojure.el" '(provide 'clojure))))

(provide 'clojure-tests)
;;; clojure-tests.el ends here
