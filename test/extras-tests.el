;;; extras-tests.el --- BDD-style ERT suite for extras.el  -*- lexical-binding: t; -*-

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

;; Headless run:
;;   emacs -Q --batch -l test/extras-tests.el -f ert-run-tests-batch-and-exit
;; or ./test/run.sh (which runs this alongside every other suite).
;;
;; Scope: extras.el ONLY -- the menu file init.el would load to enable the
;; language layers. Right now init.el's own (load "extras.el" ...) call is
;; commented out, so nothing here takes effect regardless of what is
;; uncommented in extras.el itself; every per-language (load ...) line in
;; extras.el is live code, read as ordinary top-level forms (unlike a fully
;; commented-out menu, no text-pattern matching is needed here).

(require 'ert)
(require 'seq)

;;; ------------------------------------------------------------------ locate
(defvar extras-menu-test-root
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name default-directory))))
  "Root of the init.el repo (the parent of test/).")

(defun extras-menu-test-file (name)
  "Absolute path of NAME inside the init.el repo."
  (expand-file-name name extras-menu-test-root))

(load (expand-file-name "extras/helpers" (file-name-directory
                                          (or load-file-name buffer-file-name))))

;;; --------------------------------------------------------- file as data
(defun extras-menu-test--forms (name)
  "Every top-level form in NAME (relative to the repo root), in order."
  (with-temp-buffer
    (insert-file-contents (extras-menu-test-file name))
    (goto-char (point-min))
    (let ((forms '()))
      (condition-case nil
          (while t (push (read (current-buffer)) forms))
        (end-of-file nil))
      (nreverse forms))))

(defun extras-menu-test--load-target (form)
  "If FORM is (load (expand-file-name \"extras/NAME\" ...) ...), return NAME."
  (and (consp form) (eq (car form) 'load)
       (consp (cadr form)) (eq (car (cadr form)) 'expand-file-name)
       (let ((path (cadr (cadr form))))
         (and (stringp path) (string-prefix-p "extras/" path)
              (substring path (length "extras/"))))))

;;; ================================================================ extras.el
(ert-deftest extras-menu-test/given-extras-then-it-still-parses-as-valid-elisp ()
  (should (extras-menu-test--forms "extras.el")))

(ert-deftest extras-menu-test/given-extras-then-every-loader-line-is-live-code ()
  "Every per-language (load ...) call is live, top-level code -- none of them
are commented out right now. Compared against extras-test--menu-files, not
extras-test--files -- eglot-ensure.el is a shared dependency pulled in by
`require', not a layer with its own menu entry."
  (let ((targets (delq nil (mapcar #'extras-menu-test--load-target
                                   (extras-menu-test--forms "extras.el")))))
    (should (equal targets extras-test--menu-files))))

(ert-deftest extras-menu-test/given-extras-then-every-loader-uses-noerror-nomessage ()
  "Each loader is a full, working (load ...) form -- :noerror so a layer with
no external tool installed does not break startup, :nomessage so it stays
quiet either way."
  (dolist (form (extras-menu-test--forms "extras.el"))
    (when (extras-menu-test--load-target form)
      (ert-info ((format "form: %S" form))
        (should (equal (cddr form) '(:noerror :nomessage)))))))

(ert-deftest extras-menu-test/given-extras-then-it-ends-with-provide-extras ()
  (should (equal (car (last (extras-menu-test--forms "extras.el")))
                 '(provide 'extras))))

(defun extras-menu-test--load-target-init-el (form)
  "If FORM is (load (expand-file-name \"extras.el\" ...) ...), return t."
  (and (consp form) (eq (car form) 'load)
       (consp (cadr form)) (eq (car (cadr form)) 'expand-file-name)
       (equal (cadr (cadr form)) "extras.el")))

(ert-deftest extras-menu-test/given-the-config-then-init-does-not-load-the-extras-menu ()
  "init.el's own load call for extras.el is commented out right now, so
extras.el (and every layer live inside it) is not reached at all."
  (should-not (seq-some #'extras-menu-test--load-target-init-el
                        (extras-menu-test--forms "init.el"))))

(ert-deftest extras-menu-test/given-init-then-the-extras-menu-load-call-is-only-commented ()
  "The (load \"extras.el\" ...) call must still exist in init.el's source
text, just commented out -- re-enabling it is a one-line uncomment, not a
rewrite."
  (should (string-match-p
           "^;; (load (expand-file-name \"extras\\.el\" user-emacs-directory) :noerror :nomessage)$"
           (with-temp-buffer
             (insert-file-contents (extras-menu-test-file "init.el"))
             (buffer-string)))))

(provide 'extras-menu-tests)
;;; extras-tests.el ends here
