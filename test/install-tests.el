;;; install-tests.el --- BDD-style ERT suite for install.el  -*- lexical-binding: t; -*-

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
;;   emacs -Q --batch -l test/install-tests.el -f ert-run-tests-batch-and-exit
;; or ./test/run.sh (which runs this alongside every other suite).
;;
;; Scope: install.el ONLY -- the bootstrap installer script that downloads
;; early-init.el, init.el, extras.el, and all files under extras/.

(require 'ert)
(require 'cl-lib)
(require 'seq)

;;; ------------------------------------------------------------------ locate
(defvar install-test-root
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name default-directory))))
  "Root of the init.el repo (the parent of test/).")

(defun install-test-file (name)
  "Absolute path of NAME inside the init.el repo."
  (expand-file-name name install-test-root))

(load (expand-file-name "extras/helpers" (file-name-directory
                                         (or load-file-name buffer-file-name))))

;;; --------------------------------------------------------- file as data
(defun install-test--forms ()
  "Every top-level form in install.el, in order."
  (with-temp-buffer
    (insert-file-contents (install-test-file "install.el"))
    (goto-char (point-min))
    (let ((forms '()))
      (condition-case nil
          (while t (push (read (current-buffer)) forms))
        (end-of-file nil))
      (nreverse forms))))

(defvar install-test--form
  (car (install-test--forms))
  "The top-level progn form in install.el.")

(defun install-test--installed-files ()
  "Return the list of file paths that install.el downloads."
  (pcase install-test--form
    (`(progn . ,body)
     (let* ((let-form (seq-find (lambda (f) (and (consp f) (eq (car f) 'let*))) body)))
       (pcase let-form
         (`(let* ,_bindings (dolist (,var (quote ,files)) . ,_))
          files)
         (_ (error "Could not extract installed files from let* form: %S" let-form)))))
    (_ (error "Unexpected structure in install.el: %S" install-test--form))))

;;; ================================================================ install.el
(ert-deftest install-test/given-install-then-it-parses-as-valid-elisp ()
  (should (install-test--forms))
  (should (consp install-test--form))
  (should (eq (car install-test--form) 'progn)))

(ert-deftest install-test/given-install-then-it-installs-early-init-and-init ()
  (let ((files (install-test--installed-files)))
    (should (member "early-init.el" files))
    (should (member "init.el" files))))

(ert-deftest install-test/given-install-then-it-installs-extras-el ()
  (let ((files (install-test--installed-files)))
    (should (member "extras.el" files))))

(ert-deftest install-test/given-install-then-it-installs-all-extras-files ()
  "install.el must install all extras/ files, including eglot-ensure.el."
  (let ((files (install-test--installed-files)))
    (dolist (file extras-test--files)
      (ert-info ((format "checking extras file: %s" file))
        (should (member (concat "extras/" file) files))))))

(ert-deftest install-test/given-install-then-installed-file-list-matches-repo-manifest ()
  "The full list of installed files in install.el must exactly match
early-init.el, init.el, extras.el, and every extras/*.el in the repo."
  (let ((expected (append '("early-init.el" "init.el" "extras.el")
                          (mapcar (lambda (f) (concat "extras/" f)) extras-test--files)))
        (actual (install-test--installed-files)))
    (should (equal actual expected))))

(ert-deftest install-test/given-evaluation-then-it-downloads-and-copies-all-files ()
  "Simulate evaluating install.el: verify destination paths and url-copy-file calls."
  (let ((copied-urls '())
        (copied-dests '())
        (created-dirs '())
        (messages '()))
    (cl-letf (((symbol-function 'url-copy-file)
               (lambda (url dest &optional ok-if-already-exists)
                 (should ok-if-already-exists)
                 (push url copied-urls)
                 (push dest copied-dests)))
              ((symbol-function 'make-directory)
               (lambda (dir &optional parents)
                 (should parents)
                 (push dir created-dirs)))
              ((symbol-function 'message)
               (lambda (fmt &rest args)
                 (push (apply #'format fmt args) messages))))
      (eval install-test--form t))
    (setq copied-urls (nreverse copied-urls)
          copied-dests (nreverse copied-dests)
          messages (nreverse messages))
    (let ((expected-files (install-test--installed-files))
          (base "https://raw.githubusercontent.com/chubbyhippo/init.el/refs/heads/main/")
          (dest-dir (expand-file-name "~/.config/emacs/")))
      (should (= (length copied-urls) (length expected-files)))
      (dolist (file expected-files)
        (let ((expected-url (concat base file))
              (expected-dest (expand-file-name file dest-dir)))
          (should (member expected-url copied-urls))
          (should (member expected-dest copied-dests))
          (should (member (format "Installed %s" expected-dest) messages)))))))

(provide 'install-tests)
;;; install-tests.el ends here
