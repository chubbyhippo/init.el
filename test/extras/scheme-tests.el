;;; scheme-tests.el --- ERT suite for extras/scheme.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/scheme.el (moved here when that file's
;; comments were stripped, so the rationale below still documents the tests
;; that pin its behavior down):
;;
;; Optional Scheme layer for init.el — Guile as the default Scheme, with Chez
;; kept active for SICP. Disabled by default — uncomment the matching loader at
;; the bottom of init.el to enable it. Every package here is on NonGNU ELPA, so
;; it installs through the same `package' / `use-package' setup as the rest of
;; the config (no MELPA needed).
;;
;;   scheme-mode   the major mode — BUILT IN (Emacs already maps .scm to it),
;;                 so nothing to install just to edit
;;   geiser        the interactive layer: REPL, eval-in-buffer, autodoc,
;;                 completion, jump-to-def — the "develop Scheme" piece
;;   geiser-guile  the Guile backend — the default implementation
;;   geiser-chez   the Chez Scheme backend
;;   paredit       keep the parens balanced while you edit
;;
;; You supply the interpreters:
;;   Guile  `sudo apt install guile-3.0' (already in wsl-ubuntu-settings'
;;          apt.sh); it provides plain `guile' via update-alternatives, which
;;          is geiser-guile's default binary — nothing to set here. Add
;;          `guile-3.0-doc' and `M-x geiser-doc-look-up-manual' jumps from any
;;          symbol into the Guile Info manual — the manual is the course.
;;   Chez   `sudo apt install chezscheme'. The Ubuntu package installs the
;;          binary as `chezscheme', which is why `geiser-chez-binary' is set
;;          below.
;;
;; C-c C-z starts (or jumps to) the REPL for the buffer's implementation —
;; Guile unless the buffer says otherwise; eval a defun with C-M-x, the last
;; sexp with C-x C-e. `M-x run-guile' / `M-x run-chez' start a specific REPL.
;;
;; SICP on Chez: its REPL runs most of the book (mutable pairs and top-level
;; redefinition are allowed) — pin SICP buffers to it with a file-local
;; `geiser-scheme-implementation: chez' (declared safe, so no prompt). The
;; ch.2.2.4 picture language and a few MIT-isms (`cons-stream',
;; `true'/`false'/`nil') still need small shims — or use MIT/GNU Scheme
;; (geiser-mit) or Racket's `#lang sicp' (geiser-racket), both NonGNU ELPA:
;; install the backend and add it to the two geiser vars tested below.
;;
;; scheme-mode is a `prog-mode' child, so init.el's global `my-eglot-ensure'
;; hook would fire and nag "no suitable server" — there is no Scheme LSP
;; (geiser provides eval / autodoc / completion). Opt Scheme buffers out of it
;; via advice, without editing init.el; guarded so load order doesn't matter
;; — see the eglot-is-skipped test below. cobol.el uses the same advice
;; pattern, but conditionally (until superbol-free exists); Scheme has no LSP
;; at all, so its own advice unconditionally declines.
;;
;; No `(provide 'scheme)' in the extras file — the feature/library name
;; `scheme' belongs to the built-in scheme.el (it defines scheme-mode); the
;; extras file is loaded by path from init.el, so providing it would shadow
;; the built-in. (Same reason cpp.el / python.el / go.el / erlang.el skip
;; their provides.)

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; =============================================================== scheme.el
(ert-deftest extras-test/given-scheme-then-geiser-defaults-to-guile-with-chez-active ()
  (should (member '(geiser-default-implementation 'guile)
                  (extras-test--use-package-section "scheme.el" 'geiser :custom)))
  (should (member '(geiser-active-implementations '(guile chez))
                  (extras-test--use-package-section "scheme.el" 'geiser :custom)))
  (should (member '(scheme-mode . geiser-mode)
                  (extras-test--use-package-section "scheme.el" 'geiser :hook))))

(ert-deftest extras-test/given-scheme-then-chez-binary-is-the-ubuntu-package-name ()
  (should (member '(geiser-chez-binary "chezscheme")
                  (extras-test--use-package-section "scheme.el" 'geiser-chez :custom))))

(ert-deftest extras-test/given-scheme-then-eglot-is-skipped-in-scheme-buffers ()
  (defun my-eglot-ensure () 'ran)
  (unwind-protect
      (progn
        (extras-test--eval-def "scheme.el" 'when '(fboundp 'my-eglot-ensure))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest _) t)))
          (should-not (my-eglot-ensure)))
        (cl-letf (((symbol-function 'derived-mode-p) (lambda (&rest _) nil)))
          (should (eq (my-eglot-ensure) 'ran))))
    (advice-remove 'my-eglot-ensure 'my-scheme--skip-eglot)
    (fmakunbound 'my-eglot-ensure)))

(provide 'scheme-tests)
;;; scheme-tests.el ends here
