;;; early-init-tests.el --- BDD-style ERT suite for early-init.el  -*- lexical-binding: t; -*-

;; Headless run:
;;   emacs -Q --batch -l test/early-init-tests.el -f ert-run-tests-batch-and-exit
;; or ./test/run.sh (which runs this alongside init-tests.el).
;;
;; Scope: early-init.el ONLY -- the startup-hygiene file Emacs loads before the
;; package system and before the first frame paints.  Every form in it is a
;; harmless global assignment (gc ceiling up, no frame reflow, load-prefer-newer,
;; UI bars stripped from default-frame-alist, quiet native-comp, and the
;; startup-echo-area function neutered), so the suite EVALUATES the file in this
;; batch process and asserts the resulting state, with a couple of structural
;; checks for the forms whose effect is awkward to observe headless.
;;
;; Test names are "given ... then ..." sentences (BDD-style) over built-in ERT --
;; same house style and "never MELPA" constraint as init-tests.el.

(require 'ert)
(require 'seq)

;;; ------------------------------------------------------------------ locate
(defvar early-init-test-root
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name default-directory))))
  "Root of the init.el repo (the parent of test/).")

(defun early-init-test-file (name)
  "Absolute path of NAME inside the init.el repo."
  (expand-file-name name early-init-test-root))

;;; ----------------------------------------------- early-init.el as read data
(defun early-init-test--forms (file)
  "Every top-level form in FILE, in order."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((forms '()))
      (condition-case nil
          (while t (push (read (current-buffer)) forms))
        (end-of-file nil))
      (nreverse forms))))

(defvar early-init-test--forms
  (early-init-test--forms (early-init-test-file "early-init.el"))
  "All top-level forms of early-init.el.")

(defun early-init-test--subform-p (needle tree)
  "Non-nil if NEEDLE appears anywhere within TREE (structural equality)."
  (cond ((equal needle tree) t)
        ((consp tree) (or (early-init-test--subform-p needle (car tree))
                          (early-init-test--subform-p needle (cdr tree))))
        (t nil)))

(defun early-init-test--declares (needle)
  "Non-nil if early-init.el contains NEEDLE anywhere in its source forms."
  (seq-some (lambda (f) (early-init-test--subform-p needle f))
            early-init-test--forms))

;;; ------------------------------------------- bring early-init.el to life
;; Load the file into this batch process so we can assert the state it produces.
(load (early-init-test-file "early-init.el") nil t)

;;; ================================================= startup performance
(ert-deftest early-init-test/given-startup-then-gc-is-uncapped ()
  "No GC while starting up; init.el drops the ceiling back afterwards."
  (should (= gc-cons-threshold most-positive-fixnum)))

(ert-deftest early-init-test/given-startup-then-implied-frame-resize-is-inhibited ()
  "Menu-bar/font changes should not reflow the frame during startup."
  (should (eq frame-inhibit-implied-resize t)))

;;; ================================================= load hygiene
(ert-deftest early-init-test/given-a-stale-elc-then-a-fresh-el-is-preferred ()
  (should (eq load-prefer-newer t)))

(ert-deftest early-init-test/given-startup-then-x-resources-are-ignored ()
  "Leave the config alone; do not merge X resources."
  (should (eq inhibit-x-resources t)))

;;; ================================================= quiet startup UI
(ert-deftest early-init-test/given-startup-then-the-splash-screen-is-suppressed ()
  (should (eq inhibit-startup-screen t)))

(ert-deftest early-init-test/given-startup-then-the-echo-area-message-fn-is-neutered ()
  "inhibit-startup-echo-area-message cannot silence it for this login, so the
printing function itself is aliased to ignore."
  (should (eq (symbol-function 'display-startup-echo-area-message) #'ignore)))

;;; ================================================= no-flicker first frame
(ert-deftest early-init-test/given-the-first-frame-then-the-tool-bar-is-off ()
  "Stripped via default-frame-alist so it never paints then vanishes."
  (should (equal (assq 'tool-bar-lines default-frame-alist) '(tool-bar-lines . 0))))

(ert-deftest early-init-test/given-the-first-frame-then-the-menu-bar-is-off ()
  (should (equal (assq 'menu-bar-lines default-frame-alist) '(menu-bar-lines . 0))))

(ert-deftest early-init-test/given-the-first-frame-then-vertical-scroll-bars-are-off ()
  "Pushed as a bare (vertical-scroll-bars) entry -- no width means no bar."
  (should (member '(vertical-scroll-bars) default-frame-alist)))

;;; ================================================= native compilation
(ert-deftest early-init-test/given-native-comp-then-warnings-are-silenced ()
  (should (eq native-comp-async-report-warnings-errors 'silent)))

(ert-deftest early-init-test/given-package-install-then-native-compilation-is-on ()
  (should (eq package-native-compile t)))

;;; ================================================= structural declarations
(ert-deftest early-init-test/given-early-init-then-it-strips-the-three-ui-bars ()
  "All three chrome bars are pushed onto default-frame-alist before first paint."
  (should (early-init-test--declares '(push '(tool-bar-lines . 0) default-frame-alist)))
  (should (early-init-test--declares '(push '(menu-bar-lines . 0) default-frame-alist)))
  (should (early-init-test--declares '(push '(vertical-scroll-bars) default-frame-alist))))

;;; early-init-tests.el ends here
