;;; go-tests.el --- ERT suite for extras/go.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/go.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional Go layer for init.el. Disabled by default — uncomment the matching
;; loader in extras.el to enable it.
;;
;; Most of the stack is built in: the tree-sitter major modes (go-ts-mode,
;; go-mod-ts-mode) and eglot, which init.el already hooks onto prog-mode. You
;; supply the external tools:
;;   - gopls (go install golang.org/x/tools/gopls@latest) — eglot launches it
;;     automatically for completion / xref / refactors / formatting once it's
;;     on PATH
;;   - Delve (go install github.com/go-delve/delve/cmd/dlv@latest) — driven here
;;     by dape for breakpoints/stepping
;;   - the tree-sitter grammars (go, gomod) — AUTO-INSTALLED on first load from
;;     the sources registered in :init (needs git + a C compiler on PATH; a
;;     failed build warns rather than aborting)
;;
;; ELPA-only: dape is on GNU ELPA; the major modes and eglot are built in.
;; (go-mode is MELPA-only, so it's not used here.)
;;
;; gofmt + organize-imports run on save, via gopls — but only fire when eglot
;; is actually managing the buffer; see the format-on-save test below, which
;; also pins the ORDER (organize-imports first, then format).

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ==================================================================== go.el
(ert-deftest extras-test/given-go-then-format-on-save-organizes-imports-then-formats ()
  (extras-test--eval-def "go.el" 'defun 'my-go--format-on-save)
  (let ((fn (extras-test--capture-before-save-hook-fn #'my-go--format-on-save)))
    (let (calls)
      (cl-letf (((symbol-function 'eglot-managed-p) (lambda () nil))
                ((symbol-function 'eglot-code-action-organize-imports)
                 (lambda (&rest _) (push 'organize calls)))
                ((symbol-function 'eglot-format-buffer)
                 (lambda (&rest _) (push 'format calls))))
        (funcall fn))
      (should-not calls))
    (let (calls)
      (cl-letf (((symbol-function 'eglot-managed-p) (lambda () t))
                ((symbol-function 'eglot-code-action-organize-imports)
                 (lambda (&rest _) (push 'organize calls)))
                ((symbol-function 'eglot-format-buffer)
                 (lambda (&rest _) (push 'format calls))))
        (funcall fn))
      (should (equal (nreverse calls) '(organize format))))))

(ert-deftest extras-test/given-go-then-go-and-go-mod-map-to-their-tree-sitter-modes ()
  (should (extras-test--declares "go.el" '("\\.go\\'" . go-ts-mode)))
  (should (extras-test--declares "go.el" '("/go\\.mod\\'" . go-mod-ts-mode)))
  (should (member '(go-ts-mode-indent-offset 4)
                  (extras-test--use-package-section "go.el" 'go-ts-mode :custom))))

(ert-deftest extras-test/given-go-then-gopls-workspace-configuration-is-tuned ()
  (should (extras-test--declares "go.el" 'eglot-workspace-configuration))
  (should (extras-test--declares "go.el" '(completionBudget . "200ms")))
  (should (extras-test--declares "go.el" '(deepCompletion . t)))
  (should (extras-test--declares "go.el" '(matcher . "Fuzzy"))))

(ert-deftest extras-test/given-go-then-dape-is-declared-with-no-language-specific-config ()
  (should (member t (extras-test--use-package-section "go.el" 'dape :ensure)))
  (should (member '(dape-buffer-window-arrangement 'right)
                  (extras-test--use-package-section "go.el" 'dape :custom))))

(provide 'go-tests)
;;; go-tests.el ends here
