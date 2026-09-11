;;; python-tests.el --- ERT suite for extras/python.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/python.el (moved here when that file's
;; comments were stripped, so the rationale below still documents the tests
;; that pin its behavior down):
;;
;; Optional Python layer for init.el. Disabled by default — uncomment the
;; matching loader in extras.el to enable it.
;;
;; Built in: the major mode (python / python-ts-mode) and eglot, which init.el
;; already hooks onto prog-mode. You supply the external tools:
;;   - an LSP server such as python-lsp-server (pylsp) or pyright — eglot uses
;;     whichever it finds for completion / xref / refactors
;;   - debugpy (pip install debugpy) for the dape debugger
;;
;; The fiddly part of Python in Emacs is the per-project virtualenv. buffer-env
;; handles it: it activates the project's venv (or .envrc) buffer-locally, so
;; eglot, dape, flymake, and run-python all use the right interpreter with no
;; global state. Everything here is on GNU ELPA (no MELPA needed).
;;
;; buffer-env honours direnv (.envrc) out of the box; it is also taught to
;; source a plain Unix .venv/bin/activate or a native Windows
;; .venv/Scripts/activate.bat via `buffer-env-command-alist' -- direnv, Unix
;; venv, native Windows venv are searched up the directory tree, in that
;; order (see `buffer-env-script-name' below). It hooks onto
;; `hack-local-variables' (set env when a project file opens) and
;; `comint-mode' (...and in REPL / shell buffers).
;;
;; DAP debugging pairs with eglot (no lsp-mode needed). M-x dape, pick the
;; `debugpy' config; set breakpoints with dape-breakpoint-toggle, then n / c to
;; step once a session stops.
;;
;; Optional, also on GNU ELPA — Jupyter-style `# %%' cells for data-science
;; work: code-cells, hooked onto (python-mode python-ts-mode).
;;
;; No `(provide 'python)' here — the built-in python.el already owns that
;; feature name; the extras file is loaded by path from init.el, so it isn't
;; needed.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; =============================================================== python.el
(ert-deftest extras-test/given-python-then-python-mode-remaps-to-python-ts-mode ()
  (should (extras-test--declares "python.el" '(python-mode . python-ts-mode)))
  (should (member '(python-indent-guess-indent-offset-verbose nil)
                  (extras-test--use-package-section "python.el" 'python :custom))))

(ert-deftest extras-test/given-python-then-buffer-env-activates-on-local-vars-and-comint ()
  (let ((hooks (car (extras-test--use-package-section "python.el" 'buffer-env :hook))))
    (should (member '(hack-local-variables . buffer-env-update) hooks))
    (should (member '(comint-mode          . buffer-env-update) hooks)))
  (should (member '(buffer-env-script-name '(".envrc"
                                             ".venv/bin/activate"
                                             ".venv/Scripts/activate.bat"))
                  (extras-test--use-package-section "python.el" 'buffer-env :custom))))

(provide 'python-tests)
;;; python-tests.el ends here
