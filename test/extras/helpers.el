;;; helpers.el --- shared plumbing for the extras/ test suites  -*- lexical-binding: t; -*-

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

;; Loaded by every test/extras/*-tests.el (each `load's this file directly by
;; path, so it works whether run.sh drives the whole suite or a single
;; language file is loaded on its own for a quick check).
;;
;; Scope: extras/*.el.  Most of these files are `:ensure t' packages this
;; suite does not install (cider, dape, haskell-mode, cobol-mode, zig-mode,
;; geiser, paredit, inf-ruby, yasnippet, buffer-env, reformatter, ...), so --
;; like init-tests.el does for init.el -- each suite reads its file's forms
;; as DATA and asserts the wiring structurally, only EVALUATING forms that
;; have no external-package dependency (plain defuns and eglot registration,
;; since eglot ships built into Emacs).

(require 'ert)
(require 'cl-lib)
(require 'seq)
(require 'eglot)

;; dape is an external ELPA package this suite does not install; declare its
;; one variable the zig-tests.el suite needs so `let'-binding it dynamically
;; works the same way it would once the real package is loaded.
(defvar dape-configs nil)

;;; ------------------------------------------------------------------ locate
(defvar extras-test-root
  (file-name-directory
   (directory-file-name
    (file-name-directory
     (directory-file-name
      (file-name-directory (or load-file-name buffer-file-name default-directory))))))
  "Root of the init.el repo (the parent of test/).")

(defun extras-test-file (name)
  "Absolute path of NAME (relative to extras/) inside the init.el repo."
  (expand-file-name (concat "extras/" name) extras-test-root))

(defvar extras-test--files
  '("clojure.el" "cobol.el" "cpp.el" "elixir.el" "erlang.el" "go.el" "haskell.el"
    "html.el" "java.el" "json.el" "kotlin.el" "markdown.el" "perl.el" "php.el"
    "python.el" "ruby.el" "rust.el" "scheme.el" "sql.el" "typescript.el"
    "xml.el" "yaml.el" "zig.el")
  "Every file under extras/.")

;;; --------------------------------------------------- files as read data
(defun extras-test--forms (name)
  "Every top-level form in extras/NAME, in order."
  (with-temp-buffer
    (insert-file-contents (extras-test-file name))
    (goto-char (point-min))
    (let ((forms '()))
      (condition-case nil
          (while t (push (read (current-buffer)) forms))
        (end-of-file nil))
      (nreverse forms))))

(defun extras-test--subform-p (needle tree)
  "Non-nil if NEEDLE appears anywhere within TREE (structural equality)."
  (cond ((equal needle tree) t)
        ((consp tree) (or (extras-test--subform-p needle (car tree))
                          (extras-test--subform-p needle (cdr tree))))
        (t nil)))

(defun extras-test--declares (name needle)
  "Non-nil if extras/NAME contains NEEDLE anywhere in its source forms."
  (seq-some (lambda (f) (extras-test--subform-p needle f)) (extras-test--forms name)))

(defun extras-test--use-package-section (name package keyword)
  "The forms extras/NAME puts under KEYWORD in its (use-package PACKAGE ...) block."
  (let ((body (cddr (or (seq-find (lambda (f)
                                    (and (consp f)
                                         (eq (car f) 'use-package)
                                         (eq (cadr f) package)))
                                  (extras-test--forms name))
                        (error "%s: no (use-package %s ...) block" name package))))
        (section '())
        (collecting nil))
    (dolist (form body (nreverse section))
      (cond ((eq form keyword) (setq collecting t))
            ((keywordp form) (setq collecting nil))
            (collecting (push form section))))))

(defun extras-test--eval-def (name head sym)
  "Evaluate extras/NAME's top-level (HEAD SYM ...) form; error if absent."
  (let ((form (seq-find (lambda (f) (and (consp f) (eq (car f) head) (equal (cadr f) sym)))
                        (extras-test--forms name))))
    (unless form (error "%s: no top-level (%s %s ...)" name head sym))
    (eval form t)))

(defun extras-test--eval-with-eval-after-load (name feature)
  "Evaluate the body of extras/NAME's top-level (with-eval-after-load 'FEATURE ...)."
  (let ((form (seq-find (lambda (f) (and (consp f)
                                         (eq (car f) 'with-eval-after-load)
                                         (equal (cadr f) (list 'quote feature))))
                        (extras-test--forms name))))
    (unless form (error "%s: no (with-eval-after-load '%s ...)" name feature))
    (dolist (body-form (cddr form)) (eval body-form t))))

(defun extras-test--capture-before-save-hook-fn (thunk)
  "Call THUNK with `add-hook' mocked; return the function it registered on
`before-save-hook' (buffer-locally), without touching the real hook var."
  (let (captured)
    (cl-letf (((symbol-function 'add-hook)
               (lambda (hook fn &optional _depth local)
                 (should (eq hook 'before-save-hook))
                 (should local)
                 (setq captured fn))))
      (funcall thunk))
    captured))

(provide 'extras-test-helpers)
;;; helpers.el ends here
