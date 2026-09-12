;;; init-tests.el --- BDD-style ERT suite for init.el  -*- lexical-binding: t; -*-

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
;;   emacs -Q --batch -l test/init-tests.el -f ert-run-tests-batch-and-exit
;; or ./test/run.sh (which points package-user-dir at the installed packages).
;;
;; Scope: init.el ONLY -- not the extras/ language layers.  init.el USES the
;; real meow package rather than reimplementing it, so this suite does NOT
;; retest meow's motions/selections/edits (that is meow's own job); it verifies
;; init.el's own contributions -- the canonical meow keybinding layout the
;; sibling editor plugins port, the C-c w window/zoom maps, the custom window
;; commands, and the meow state-integration invariants.
;;
;; Test names are written as "given ... then ..." sentences (BDD-style) even
;; though the framework is built-in ERT (this config's rules are "built-ins
;; first" and "never MELPA", so buttercup is out).
;;
;; meow -- the one non-built-in dependency exercised here -- is loaded from the
;; installed packages when present, else installed from NonGNU ELPA.

(require 'ert)
(require 'cl-lib)
(require 'package)
(require 'seq)

;;; ------------------------------------------------------------------ locate
(defvar init-test-root
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name default-directory))))
  "Root of the init.el repo (the parent of test/).")

(defun init-test-file (name)
  "Absolute path of NAME inside the init.el repo."
  (expand-file-name name init-test-root))

;;; -------------------------------------------------------------- load meow
(unless (bound-and-true-p package--initialized)
  (setq package-archives
        '(("gnu"    . "https://elpa.gnu.org/packages/")
          ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
  (package-initialize))
(unless (package-installed-p 'meow)
  (package-refresh-contents)
  (package-install 'meow))
(require 'use-package)
(require 'meow)

;;; --------------------------------------------------- init.el as read data
;; Read init.el's top-level forms so we can evaluate individual definitions in
;; isolation, and assert that a convention is declared, WITHOUT loading the
;; whole config (which would pull every package it configures).
(defun init-test--forms (file)
  "Every top-level form in FILE, in order."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((forms '()))
      (condition-case nil
          (while t (push (read (current-buffer)) forms))
        (end-of-file nil))
      (nreverse forms))))

(defvar init-test--init-forms (init-test--forms (init-test-file "init.el"))
  "All top-level forms of init.el.")

(defun init-test--eval-def (head name)
  "Evaluate init.el's top-level (HEAD NAME ...) form; error if it is gone."
  (let ((form (seq-find (lambda (f)
                          (and (consp f) (eq (car f) head) (eq (cadr f) name)))
                        init-test--init-forms)))
    (unless form (error "init.el: no top-level (%s %s ...) form" head name))
    (eval form t)))

(defun init-test--subform-p (needle tree)
  "Non-nil if NEEDLE appears anywhere within TREE (structural equality)."
  (cond ((equal needle tree) t)
        ((consp tree) (or (init-test--subform-p needle (car tree))
                          (init-test--subform-p needle (cdr tree))))
        (t nil)))

(defun init-test--declares (needle)
  "Non-nil if init.el contains NEEDLE anywhere in its source forms."
  (seq-some (lambda (f) (init-test--subform-p needle f)) init-test--init-forms))

(defun init-test--use-package-section (package keyword)
  "The forms init.el puts under KEYWORD in its (use-package PACKAGE ...) block.
Presence in the source is not enough for a deferred package: :init runs at
startup, :config only when the package finally loads."
  (let ((body (cddr (or (seq-find (lambda (f)
                                    (and (consp f)
                                         (eq (car f) 'use-package)
                                         (eq (cadr f) package)))
                                  init-test--init-forms)
                        (error "init.el: no (use-package %s ...) block" package))))
        (section '())
        (collecting nil))
    (dolist (form body (nreverse section))
      (cond ((eq form keyword) (setq collecting t))
            ((keywordp form) (setq collecting nil))
            (collecting (push form section))))))

(defun init-test--eval-section-def (package section head name)
  "Evaluate the (HEAD NAME ...) form from PACKAGE's SECTION (:init, :preface, etc.) in init.el."
  (let ((form (seq-find (lambda (f)
                          (and (consp f) (eq (car f) head) (eq (cadr f) name)))
                        (init-test--use-package-section package section))))
    (unless form (error "init.el: no (%s %s ...) in %s's %s" head name package section))
    (eval form t)))

(defun init-test--eval-init-def (package head name)
  "Evaluate the (HEAD NAME ...) form from PACKAGE's :init section in init.el."
  (init-test--eval-section-def package :init head name))

;;; ---------------------------------------------- bring the units to life
;; Evaluating the meow use-package block defines and calls my-meow-setup, which
;; populates meow's normal/motion state keymaps and the leader map
;; (mode-specific-map), and sets M-SPC globally.  The window/zoom keymaps and
;; the custom window commands are plain top-level forms.
(init-test--eval-def 'use-package 'meow)
(dolist (km '(my-window-map my-window-resize-map
              my-text-scale-repeat-map my-winner-repeat-map))
  (init-test--eval-def 'defvar-keymap km))
(dolist (fn '(my-text-scale-reset my-window-resize
              my-edit-init-file my-reload-init-file
              my-restore-gc-defaults))
  (init-test--eval-def 'defun fn))

(defun init-test--normal (key) (keymap-lookup meow-normal-state-keymap key))
(defun init-test--motion (key) (keymap-lookup meow-motion-state-keymap key))
(defun init-test--leader (key) (keymap-lookup mode-specific-map key))

;;; ================================================= meow NORMAL conventions
(ert-deftest init-test/given-normal-state-then-hjkl-are-directional-motions ()
  "The home row keys move by char/line like the ports' h/j/k/l."
  (should (eq (init-test--normal "h") 'meow-left))
  (should (eq (init-test--normal "j") 'meow-next))
  (should (eq (init-test--normal "k") 'meow-prev))
  (should (eq (init-test--normal "l") 'meow-right)))

(ert-deftest init-test/given-normal-state-then-S-is-avy-goto-char-timer ()
  "This config's signature deviation from stock meow (the ports mirror it)."
  (should (eq (init-test--normal "S") 'avy-goto-char-timer)))

(ert-deftest init-test/given-normal-state-then-Q-is-avy-goto-line ()
  (should (eq (init-test--normal "Q") 'avy-goto-line)))

(ert-deftest init-test/given-normal-state-then-X-keeps-meow-goto-line ()
  "S/Q take the avy jumps; X keeps goto-line."
  (should (eq (init-test--normal "X") 'meow-goto-line)))

(ert-deftest init-test/given-normal-state-then-F-and-T-expand-find-and-till ()
  "meow's own suggested layout leaves F/T unbound; this config uses them to
extend the current selection to a char (e.g. after w e e e, F\" / T; grows the
selection to/up-to that delimiter) instead of replacing it like plain f/t do."
  (should (eq (init-test--normal "f") 'meow-find))
  (should (eq (init-test--normal "F") 'meow-find-expand))
  (should (eq (init-test--normal "t") 'meow-till))
  (should (eq (init-test--normal "T") 'meow-till-expand)))

(ert-deftest init-test/given-normal-state-then-G-is-meow-grab ()
  (should (eq (init-test--normal "G") 'meow-grab)))

(ert-deftest init-test/given-meow-grab-then-secondary-selection-matches-ideameow-grab-color ()
  "meow-grab uses Emacs's built-in secondary-selection face (meow-face.el reads
its background directly); #C0F0CD is the light half of ideameow's theme-split
grab-color default."
  (should (init-test--declares '(set-face-attribute 'secondary-selection nil
                                                     :background "#C0F0CD"))))

(ert-deftest init-test/given-normal-state-then-i-and-a-enter-and-append-insert ()
  (should (eq (init-test--normal "i") 'meow-insert))
  (should (eq (init-test--normal "a") 'meow-append)))

(ert-deftest init-test/given-normal-state-then-x-marks-the-line ()
  (should (eq (init-test--normal "x") 'meow-line)))

(ert-deftest init-test/given-normal-state-then-quote-repeats ()
  (should (eq (init-test--normal "'") 'repeat)))

(ert-deftest init-test/given-normal-state-then-digits-expand-the-selection ()
  (should (eq (init-test--normal "0") 'meow-expand-0))
  (should (eq (init-test--normal "9") 'meow-expand-9))
  (should (eq (init-test--normal "1") 'meow-expand-1)))

(ert-deftest init-test/given-normal-state-then-t-is-mapped-to-tag-thing ()
  "Tag thing registered on ?t in meow-char-thing-table."
  (should (eq (cdr (assq ?t meow-char-thing-table)) 'tag)))

(ert-deftest init-test/given-normal-state-then-parens-are-mapped-to-round-thing ()
  "Parentheses ?( and ?) are registered as aliases for round in meow-char-thing-table."
  (should (eq (cdr (assq ?\( meow-char-thing-table)) 'round))
  (should (eq (cdr (assq ?\) meow-char-thing-table)) 'round))
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(hello world)")
    (goto-char 5)
    (should (equal (meow--parse-inner-of-thing-char ?\() '(2 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?\() '(1 . 14)))
    (should (equal (meow--parse-inner-of-thing-char ?\)) '(2 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?\)) '(1 . 14)))))

(ert-deftest init-test/given-normal-state-then-brackets-are-mapped-to-square-thing ()
  "Square brackets ?[ and ?] are registered as aliases for square in meow-char-thing-table."
  (should (eq (cdr (assq ?\[ meow-char-thing-table)) 'square))
  (should (eq (cdr (assq ?\] meow-char-thing-table)) 'square))
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "[hello world]")
    (goto-char 5)
    (should (equal (meow--parse-inner-of-thing-char ?\[) '(2 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?\[) '(1 . 14)))
    (should (equal (meow--parse-inner-of-thing-char ?\]) '(2 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?\]) '(1 . 14)))))

(ert-deftest init-test/given-normal-state-then-braces-are-mapped-to-curly-thing ()
  "Curly braces ?{ and ?} are registered as aliases for curly in meow-char-thing-table."
  (should (eq (cdr (assq ?{ meow-char-thing-table)) 'curly))
  (should (eq (cdr (assq ?} meow-char-thing-table)) 'curly))
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "{hello world}")
    (goto-char 5)
    (should (equal (meow--parse-inner-of-thing-char ?{) '(2 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?{) '(1 . 14)))
    (should (equal (meow--parse-inner-of-thing-char ?}) '(2 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?}) '(1 . 14)))))

(ert-deftest init-test/given-normal-state-then-quotes-are-mapped-to-string-thing ()
  "Quote characters ?' and ?\" are registered as aliases for string in meow-char-thing-table."
  (should (eq (cdr (assq ?\' meow-char-thing-table)) 'string))
  (should (eq (cdr (assq ?\" meow-char-thing-table)) 'string))
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "\"hello world\"")
    (goto-char 5)
    (should (equal (meow--parse-inner-of-thing-char ?\') '(2 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?\') '(1 . 14)))
    (should (equal (meow--parse-inner-of-thing-char ?\") '(2 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?\") '(1 . 14)))))

(ert-deftest init-test/given-normal-state-then-angle-brackets-are-mapped-to-angle-thing ()
  "Angle brackets ?< and ?> (and ?a) are registered for angle brackets in meow-char-thing-table."
  (should (eq (cdr (assq ?a meow-char-thing-table)) 'angle))
  (should (eq (cdr (assq ?< meow-char-thing-table)) 'angle))
  (should (eq (cdr (assq ?> meow-char-thing-table)) 'angle))
  (with-temp-buffer
    (insert "foo <bar baz> qux")
    (goto-char 8)
    (should (equal (meow--parse-inner-of-thing-char ?<) '(6 . 13)))
    (should (equal (buffer-substring-no-properties 6 13) "bar baz"))
    (should (equal (meow--parse-bounds-of-thing-char ?<) '(5 . 14)))
    (should (equal (buffer-substring-no-properties 5 14) "<bar baz>"))
    (should (equal (meow--parse-inner-of-thing-char ?>) '(6 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?>) '(5 . 14)))
    (should (equal (meow--parse-inner-of-thing-char ?a) '(6 . 13)))
    (should (equal (meow--parse-bounds-of-thing-char ?a) '(5 . 14)))))

(ert-deftest init-test/given-normal-state-then-slash-and-question-are-mapped-to-things ()
  "Slash ?/ and question ?\\? are registered for delimiter matching in meow-char-thing-table."
  (should (eq (cdr (assq ?/ meow-char-thing-table)) 'slash))
  (should (eq (cdr (assq ?\? meow-char-thing-table)) 'question))
  (with-temp-buffer
    (insert "foo /bar baz/ qux")
    (goto-char 8)
    (should (equal (meow--parse-inner-of-thing-char ?/) '(6 . 13)))
    (should (equal (buffer-substring-no-properties 6 13) "bar baz"))
    (should (equal (meow--parse-bounds-of-thing-char ?/) '(5 . 14)))
    (should (equal (buffer-substring-no-properties 5 14) "/bar baz/")))
  (with-temp-buffer
    (insert "foo ?bar baz? qux")
    (goto-char 8)
    (should (equal (meow--parse-inner-of-thing-char ?\?) '(6 . 13)))
    (should (equal (buffer-substring-no-properties 6 13) "bar baz"))
    (should (equal (meow--parse-bounds-of-thing-char ?\?) '(5 . 14)))
    (should (equal (buffer-substring-no-properties 5 14) "?bar baz?"))))

(ert-deftest init-test/given-tag-thing-then-inner-and-bounds-resolve-html-and-xml-tags ()
  "Inner of tag selects content between > and <; bounds select full <tag>...</tag>."
  (with-temp-buffer
    (insert "<div class=\"hero\"><p>Hello World</p></div>")
    ;; Inside inner <p> tag
    (goto-char 24)
    (should (equal (meow--parse-inner-of-thing-char ?t) '(22 . 33)))
    (should (equal (buffer-substring-no-properties 22 33) "Hello World"))
    (should (equal (meow--parse-bounds-of-thing-char ?t) '(19 . 37)))
    (should (equal (buffer-substring-no-properties 19 37) "<p>Hello World</p>"))
    ;; On opening <div...> tag
    (goto-char 5)
    (should (equal (meow--parse-inner-of-thing-char ?t) '(19 . 37)))
    (should (equal (meow--parse-bounds-of-thing-char ?t) '(1 . 43)))))

(ert-deftest init-test/given-normal-state-then-escape-is-ignored ()
  (should (eq (init-test--normal "<escape>") 'ignore)))

;;; ================================================= meow MOTION + LEADER
(ert-deftest init-test/given-motion-state-then-jk-move-and-escape-is-ignored ()
  "MOTION (read-only buffers): j/k move, ESC does nothing."
  (should (eq (init-test--motion "j") 'meow-next))
  (should (eq (init-test--motion "k") 'meow-prev))
  (should (eq (init-test--motion "<escape>") 'ignore)))

(ert-deftest init-test/given-the-leader-then-digits-are-a-numeric-count ()
  (should (eq (init-test--leader "1") 'meow-digit-argument))
  (should (eq (init-test--leader "0") 'meow-digit-argument)))

(ert-deftest init-test/given-the-leader-then-slash-describes-and-question-cheatsheets ()
  (should (eq (init-test--leader "/") 'meow-keypad-describe-key))
  (should (eq (init-test--leader "?") 'meow-cheatsheet)))

(ert-deftest init-test/given-the-leader-then-s-is-consult-line ()
  "Spelled out so keypad translation does not drop it."
  (should (eq (init-test--leader "s") 'consult-line)))

(ert-deftest init-test/given-the-leader-then-b-b-is-consult-buffer ()
  "One key deeper so a bare b does not clobber the C-c b bookmark prefix."
  (should (eq (init-test--leader "b b") 'consult-buffer)))

(ert-deftest init-test/given-the-leader-then-e-e-is-expreg-expand ()
  "SPC e e expands region."
  (should (eq (init-test--leader "e e") 'expreg-expand)))

(ert-deftest init-test/given-the-leader-then-f-o-is-eglot-format-buffer ()
  "Joins the existing f prefix (C-c f f = find-file) without touching it."
  (should (eq (init-test--leader "f o") 'eglot-format-buffer))
  (should-not (init-test--leader "f f")))

(ert-deftest init-test/given-the-leader-then-f-s-is-save-buffer ()
  "f s saves unconditionally so before-save-hook (format-on-save layers like
extras/go.el) always fires, unlike SPC x s's C-x s project-save-some-buffers
keypad fallback which prompts per buffer and can skip declined saves."
  (should (eq (init-test--leader "f s") 'save-buffer))
  (should-not (init-test--leader "f f")))

(ert-deftest init-test/given-the-leader-then-i-group-also-hosts-consult-imenu ()
  "SPC i i / i m are consult-imenu / consult-imenu-multi, sharing the i
prefix with eglot-code-action-inline rather than spawning a new prefix."
  (should (eq (init-test--leader "i i") 'consult-imenu))
  (should (eq (init-test--leader "i m") 'consult-imenu-multi)))

(ert-deftest init-test/given-the-leader-then-i-n-is-eglot-code-action-inline ()
  "SPC i n mirrors C-c i n verbatim; organize-imports lives under o instead,
so i is otherwise free for consult-imenu to ride along on."
  (should (eq (init-test--leader "i n") 'eglot-code-action-inline)))

(ert-deftest init-test/given-the-leader-then-j-group-also-hosts-xref ()
  "Eglot has no find-references/apropos/back of its own; xref fills the j group.
 xref-find-definitions is the far more common lookup, so it takes j d,
 bumping Eglot's declaration finder to j D."
  (should (eq (init-test--leader "j d") 'xref-find-definitions))
  (should (eq (init-test--leader "j r") 'xref-find-references))
  (should (eq (init-test--leader "j a") 'xref-find-apropos))
  (should (eq (init-test--leader "j b") 'xref-go-back)))

(ert-deftest init-test/given-the-leader-then-j-group-is-eglot-goto-commands ()
  "SPC j D/i/t mirror C-c d / C-c I / C-c t under a j (jump/goto) prefix."
  (should (eq (init-test--leader "j D") 'eglot-find-declaration))
  (should (eq (init-test--leader "j i") 'eglot-find-implementation))
  (should (eq (init-test--leader "j t") 'eglot-find-typeDefinition)))

(ert-deftest init-test/given-the-leader-then-L-group-is-eglot-session-management ()
  "eglot's raw list-connections lives at C-c l c, but l is already a leaf
command elsewhere on mode-specific-map (org-store-link); nesting there would
have clobbered it, so reconnect/shutdown-all/list-connections/events-buffer
all moved to a capital L prefix instead, and my-meow-setup itself must leave
the bare l key alone."
  (should (init-test--declares '("C-c l" . org-store-link)))
  (should-not (init-test--leader "l"))
  (should (eq (init-test--leader "L r") 'eglot-reconnect))
  (should (eq (init-test--leader "L s") 'eglot-shutdown-all))
  (should (eq (init-test--leader "L c") 'eglot-list-connections))
  (should (eq (init-test--leader "L e") 'eglot-events-buffer)))

(ert-deftest init-test/given-the-leader-then-o-group-is-org-entry-points ()
  "SPC o a / o c / o l mirror C-c a / C-c c / C-c l."
  (should (eq (init-test--leader "o a") 'org-agenda))
  (should (eq (init-test--leader "o c") 'org-capture))
  (should (eq (init-test--leader "o l") 'org-store-link)))

(ert-deftest init-test/given-the-leader-then-organize-imports-joins-the-o-prefix ()
  "SPC o i mirrors C-c o i verbatim, joining the existing o (org) prefix --
same trick as r/f sharing eglot commands with ripgrep/find-file -- rather
than introducing a whole new prefix for a single command."
  (should (eq (init-test--leader "o i") 'eglot-code-action-organize-imports))
  (should (eq (init-test--leader "o a") 'org-agenda)))

(ert-deftest init-test/given-the-leader-then-p-group-is-project-navigation ()
  "SPC p f/p/e/g/d/c/k/v/b/s mirror the whole C-x p prefix without the C-x detour."
  (should (eq (init-test--leader "p f") 'project-find-file))
  (should (eq (init-test--leader "p p") 'project-switch-project))
  (should (eq (init-test--leader "p e") 'project-eshell))
  (should (eq (init-test--leader "p g") 'project-find-regexp))
  (should (eq (init-test--leader "p d") 'project-dired))
  (should (eq (init-test--leader "p c") 'project-compile))
  (should (eq (init-test--leader "p k") 'project-kill-buffers))
  (should (eq (init-test--leader "p v") 'project-vc-dir))
  (should (eq (init-test--leader "p b") 'project-switch-to-buffer))
  (should (eq (init-test--leader "p s") 'project-shell)))

(ert-deftest init-test/given-the-leader-then-r-g-is-consult-ripgrep ()
  "Nested under r (shared with eglot's rename/rewrite) so C-c r can stay a
prefix; matches the global C-c r g bind."
  (should (eq (init-test--leader "r g") 'consult-ripgrep)))

(ert-deftest init-test/given-the-leader-then-r-n-is-eglot-rename ()
  "SPC r n is a direct shortcut for eglot-rename, skipping the raw C-c
keypad spelling."
  (should (eq (init-test--leader "r n") 'eglot-rename)))

(ert-deftest init-test/given-the-leader-then-eglot-refactor-actions-join-the-r-prefix ()
  "eglot-mode-map is buffer-local, so its own C-c bindings never reach the
shared mode-specific-map leader on their own; rewrite/extract/quickfix/actions
join r n/r g as siblings under the same prefix."
  (should (eq (init-test--leader "r w") 'eglot-code-action-rewrite))
  (should (eq (init-test--leader "r x") 'eglot-code-action-extract))
  (should (eq (init-test--leader "r q") 'eglot-code-action-quickfix))
  (should (eq (init-test--leader "r a") 'eglot-code-actions)))

(ert-deftest init-test/given-the-leader-then-r-a-is-eglot-code-actions ()
  "eglot-code-actions has no raw C-c binding at all -- it only exists as
M-RET and the leader's r a -- so nothing on mode-specific-map can collide
with it; my-meow-setup still must leave the bare c key (org-capture) alone."
  (should (init-test--declares '("C-c c" . org-capture)))
  (should-not (init-test--leader "c"))
  (should (eq (init-test--leader "r a") 'eglot-code-actions)))

(ert-deftest init-test/given-the-leader-then-v-group-is-version-control ()
  "SPC v c/b/l/d/f run Magit commands under the v (version control) prefix."
  (should (eq (init-test--leader "v c") 'magit-status))
  (should (eq (init-test--leader "v b") 'magit-blame))
  (should (eq (init-test--leader "v l") 'magit-log))
  (should (eq (init-test--leader "v d") 'magit-diff))
  (should (eq (init-test--leader "v f") 'magit-file-dispatch)))

(ert-deftest init-test/given-the-leader-then-v-group-has-more-magit-mnemonics ()
  "SPC v P/p/m/M/r/t/s/S/C/R/w mirror magit-dispatch's own letters where free."
  (should (eq (init-test--leader "v P") 'magit-push))
  (should (eq (init-test--leader "v p") 'magit-pull))
  (should (eq (init-test--leader "v m") 'magit-merge))
  (should (eq (init-test--leader "v M") 'magit-remote))
  (should (eq (init-test--leader "v r") 'magit-rebase))
  (should (eq (init-test--leader "v t") 'magit-tag))
  (should (eq (init-test--leader "v s") 'magit-status))
  (should (eq (init-test--leader "v S") 'magit-stash))
  (should (eq (init-test--leader "v C") 'magit-commit))
  (should (eq (init-test--leader "v R") 'magit-reset))
  (should (eq (init-test--leader "v w") 'magit-worktree)))

(ert-deftest init-test/given-the-leader-then-comma-and-dot-groups-navigate-hunks-and-errors ()
  "SPC ,/. c = previous/next hunk (diff-hl); ,/. e = error (flymake)."
  (should (eq (init-test--leader ", c") 'diff-hl-previous-hunk))
  (should (eq (init-test--leader ", e") 'flymake-goto-prev-error))
  (should (eq (init-test--leader ". c") 'diff-hl-next-hunk))
  (should (eq (init-test--leader ". e") 'flymake-goto-next-error)))

;;; ================================================= C-c w window map
(ert-deftest init-test/given-the-window-map-then-w-switches-and-W-swaps ()
  "w = jump (ace-window remaps it live), W = swap by label."
  (should (eq (keymap-lookup my-window-map "w") 'other-window))
  (should (eq (keymap-lookup my-window-map "W") 'ace-swap-window)))

(ert-deftest init-test/given-the-window-map-then-hjkl-move-and-HJKL-swap-window-states ()
  (should (eq (keymap-lookup my-window-map "h") 'windmove-left))
  (should (eq (keymap-lookup my-window-map "j") 'windmove-down))
  (should (eq (keymap-lookup my-window-map "k") 'windmove-up))
  (should (eq (keymap-lookup my-window-map "l") 'windmove-right))
  (should (eq (keymap-lookup my-window-map "H") 'windmove-swap-states-left))
  (should (eq (keymap-lookup my-window-map "J") 'windmove-swap-states-down))
  (should (eq (keymap-lookup my-window-map "K") 'windmove-swap-states-up))
  (should (eq (keymap-lookup my-window-map "L") 'windmove-swap-states-right)))

(ert-deftest init-test/given-the-window-map-then-r-resizes-via-my-window-resize ()
  (should (eq (keymap-lookup my-window-map "r") 'my-window-resize)))

(ert-deftest init-test/given-the-window-map-then-b-balances-and-comma-dot-walk-winner ()
  (should (eq (keymap-lookup my-window-map "b") 'balance-windows))
  (should (eq (keymap-lookup my-window-map ",") 'winner-undo))
  (should (eq (keymap-lookup my-window-map ".") 'winner-redo)))

(ert-deftest init-test/given-the-window-map-then-zoom-keys-scale-and-reset-text ()
  "i/= zoom in, o/- zoom out, u/0 reset (home aliases of the symbol keys)."
  (should (eq (keymap-lookup my-window-map "i") 'text-scale-increase))
  (should (eq (keymap-lookup my-window-map "=") 'text-scale-increase))
  (should (eq (keymap-lookup my-window-map "o") 'text-scale-decrease))
  (should (eq (keymap-lookup my-window-map "-") 'text-scale-decrease))
  (should (eq (keymap-lookup my-window-map "u") 'my-text-scale-reset))
  (should (eq (keymap-lookup my-window-map "0") 'my-text-scale-reset)))

(ert-deftest init-test/given-the-resize-map-then-hjkl-and-arrows-resize-the-window ()
  (should (eq (keymap-lookup my-window-resize-map "l") 'enlarge-window-horizontally))
  (should (eq (keymap-lookup my-window-resize-map "<right>") 'enlarge-window-horizontally))
  (should (eq (keymap-lookup my-window-resize-map "h") 'shrink-window-horizontally))
  (should (eq (keymap-lookup my-window-resize-map "<left>") 'shrink-window-horizontally))
  (should (eq (keymap-lookup my-window-resize-map "j") 'enlarge-window))
  (should (eq (keymap-lookup my-window-resize-map "<down>") 'enlarge-window))
  (should (eq (keymap-lookup my-window-resize-map "k") 'shrink-window))
  (should (eq (keymap-lookup my-window-resize-map "<up>") 'shrink-window)))

;;; ================================================= repeat maps
(ert-deftest init-test/given-the-text-scale-repeat-map-then-zoom-keys-repeat ()
  (should (keymapp my-text-scale-repeat-map))
  (should (eq (keymap-lookup my-text-scale-repeat-map "i") 'text-scale-increase))
  (should (eq (keymap-lookup my-text-scale-repeat-map "o") 'text-scale-decrease))
  (should (eq (keymap-lookup my-text-scale-repeat-map "u") 'my-text-scale-reset))
  (should (eq (get 'text-scale-increase 'repeat-map) 'my-text-scale-repeat-map)))

(ert-deftest init-test/given-the-winner-repeat-map-then-comma-dot-repeat-window-history ()
  (should (keymapp my-winner-repeat-map))
  (should (eq (keymap-lookup my-winner-repeat-map ",") 'winner-undo))
  (should (eq (keymap-lookup my-winner-repeat-map ".") 'winner-redo))
  (should (eq (get 'winner-undo 'repeat-map) 'my-winner-repeat-map)))

;;; ================================================= custom commands
(ert-deftest init-test/given-my-text-scale-reset-then-it-is-an-interactive-command ()
  (should (commandp 'my-text-scale-reset)))

(ert-deftest init-test/given-my-window-resize-then-it-is-an-interactive-command ()
  (should (commandp 'my-window-resize)))

(ert-deftest init-test/given-my-edit-init-file-then-it-is-an-interactive-command ()
  (should (commandp 'my-edit-init-file)))

(ert-deftest init-test/given-my-reload-init-file-then-it-is-an-interactive-command ()
  (should (commandp 'my-reload-init-file)))

(ert-deftest init-test/given-my-restore-gc-defaults-then-it-is-a-plain-function ()
  "Named (not anonymous) so `add-hook' can de-dupe it across reloads."
  (should (fboundp 'my-restore-gc-defaults))
  (should-not (commandp 'my-restore-gc-defaults)))

(ert-deftest init-test/given-repeated-reloads-then-the-gc-restore-hook-does-not-duplicate ()
  "my-reload-init-file re-evaluates init.el; a named hook function lets
add-hook de-dupe instead of stacking a fresh anonymous lambda each time."
  (let ((emacs-startup-hook nil))
    (add-hook 'emacs-startup-hook #'my-restore-gc-defaults)
    (add-hook 'emacs-startup-hook #'my-restore-gc-defaults)
    (should (equal emacs-startup-hook '(my-restore-gc-defaults)))))

;;; ================================================= config invariants
(ert-deftest init-test/given-the-config-then-M-SPC-reaches-the-leader-from-insert ()
  (should (eq (keymap-lookup (current-global-map) "M-SPC") 'meow-keypad)))

(ert-deftest init-test/given-the-config-then-eat-terminals-run-in-insert-state ()
  "A pager needs SPC/j/k, so eat-mode is forced to INSERT, not MOTION."
  (should (init-test--declares '(eat-mode . insert))))

(ert-deftest init-test/given-the-config-then-magit-buffers-stay-in-motion-state ()
  "NORMAL would stomp magit's single-key s/c/p/f/l/d commands."
  (should (init-test--declares 'magit-status-mode))
  (should (init-test--declares '(add-to-list 'meow-mode-state-list (cons mode 'motion)))))


(ert-deftest init-test/given-the-config-then-wgrep-edits-flip-the-buffer-to-normal ()
  "wgrep only swaps the local keymap, so an advice flips meow to NORMAL on edit."
  (should (init-test--declares 'wgrep-change-to-wgrep-mode))
  (should (init-test--declares '(meow--switch-state 'normal))))

;;; ============================================ removed-comment coverage
;; The following specs preserve the rationale that used to live as inline
;; comments in init.el.  Each docstring carries the WHY; each assertion pins
;; the declaration the comment was explaining, so the knowledge is enforced
;; rather than merely narrated.  They are structural (`init-test--declares')
;; because they cover config blocks the isolated-eval harness above does not
;; instantiate (loading them would pull every package init.el configures).

;;; --------------------------------------------------- built-in emacs block
(ert-deftest init-test/given-startup-over-then-the-gc-ceiling-drops-back-to-16mb ()
  "early-init.el cranks gc-cons-threshold to the max for a fast startup; this
hook drops it back to a sane 16 MB once `emacs-startup-hook' fires."
  (should (init-test--declares '(setq gc-cons-threshold (* 16 1024 1024)
                                        gc-cons-percentage 0.1)))
  (should (init-test--declares
           '(add-hook 'emacs-startup-hook #'my-restore-gc-defaults))))

(ert-deftest init-test/given-startup-over-then-file-name-handlers-are-restored ()
  "early-init.el emptied file-name-handler-alist; restore the stashed value
so tramp/compression handlers work after startup."
  (should (init-test--declares
           '(setq file-name-handler-alist my--file-name-handler-alist))))

(ert-deftest init-test/given-a-save-then-backups-autosaves-and-locks-live-under-var ()
  "Redirect litter out of project trees into user-emacs-directory/var/."
  (should (init-test--declares
           '(backup-dir (expand-file-name "var/backup/" user-emacs-directory))))
  (should (init-test--declares
           '(auto-save-dir (expand-file-name "var/auto-save/" user-emacs-directory))))
  (should (init-test--declares
           '(lock-dir (expand-file-name "var/lock/" user-emacs-directory))))
  (should (init-test--declares 'backup-directory-alist))
  (should (init-test--declares 'auto-save-file-name-transforms))
  (should (init-test--declares 'lock-file-name-transforms)))

(ert-deftest init-test/given-font-available-then-jetbrains-mono-and-line-spacing-are-set ()
  "When JetBrainsMono Nerd Font is available, use it at size 13 with line spacing 0.2."
  (should (init-test--declares '(find-font (font-spec :name "JetBrainsMono Nerd Font"))))
  (should (init-test--declares '(set-face-attribute 'default nil :family "JetBrainsMono Nerd Font" :height 130)))
  (should (init-test--declares '(setq-default line-spacing 0.2))))

(ert-deftest init-test/given-a-terminal-frame-then-the-mouse-is-enabled ()
  "GUI frames already support the mouse natively; xterm-mouse-mode teaches a
tty to decode click/drag/wheel escape sequences from the terminal emulator."
  (should (init-test--declares '(unless (display-graphic-p)
                                  (xterm-mouse-mode 1)))))

(ert-deftest init-test/given-a-pathological-file-then-so-long-mode-guards-it ()
  "Files with pathologically long lines (minified JS, logs) wedge Emacs;
global-so-long-mode neutralizes them."
  (should (init-test--declares '(global-so-long-mode 1))))

(ert-deftest init-test/given-emacs-30-then-completion-preview-coexists-with-corfu ()
  "Emacs 30's built-in ghost-text preview is enabled (guarded by fboundp) and
runs happily alongside corfu."
  (should (init-test--declares '(when (fboundp 'global-completion-preview-mode)
                                  (global-completion-preview-mode 1)))))

(ert-deftest init-test/given-lsp-io-then-the-process-read-buffer-is-1mb ()
  "read-process-output-max is raised from the 64 KB default to 1 MB so large
LSP responses arrive in fewer chunks — snappier eglot."
  (should (init-test--declares '(setq read-process-output-max (* 1024 1024)))))

(ert-deftest init-test/given-the-config-then-redisplay-favors-speed-over-precision ()
  "The four scrolling/fontification/font-cache knobs the Emacs manual and
NEWS.25.2 themselves recommend for a smoother, less stuttery redisplay --
not community folklore like scroll-conservatively or bidi-display-reordering,
which the manual/docstring explicitly do NOT endorse for performance."
  (should (init-test--declares '(setq fast-but-imprecise-scrolling t
                                  redisplay-skip-fontification-on-input t
                                  jit-lock-defer-time 0.1
                                  inhibit-compacting-font-caches t))))

(ert-deftest init-test/given-customize-then-its-writes-go-to-a-separate-file ()
  "M-x customize saves are redirected to custom.el so they never rewrite this
hand-curated init.el."
  (should (init-test--declares '(setq custom-file (locate-user-emacs-file "custom.el"))))
  (should (init-test--declares '(load custom-file 'noerror))))

(ert-deftest init-test/given-the-bell-then-it-is-visual ()
  "visible-bell is enabled in use-package emacs so error rings flash visually."
  (should (init-test--declares '(visible-bell t))))

(ert-deftest init-test/given-no-active-region-then-C-w-kills-the-last-word ()
  "kill-region-dwim (Emacs 31) makes C-w fall back to unix-word-rubout instead
of erroring when there is no region to kill."
  (should (init-test--declares '(kill-region-dwim t))))

(ert-deftest init-test/given-save-place-then-it-also-autosaves-periodically ()
  "save-place-mode already saves on kill-emacs; save-place-autosave-interval
(Emacs 31) additionally saves every 5 minutes so a crash loses less."
  (should (init-test--declares '(save-place-autosave-interval 300))))

(ert-deftest init-test/given-vc-tracked-files-then-vc-auto-revert-mode-is-armed ()
  "vc-auto-revert-mode (Emacs 31) is a more reliable complement to
global-auto-revert-mode's auto-revert-check-vc-info for VCS-tracked files."
  (should (init-test--declares '(when (fboundp 'vc-auto-revert-mode)
                                  (vc-auto-revert-mode 1)))))

(ert-deftest init-test/given-recentf-then-it-also-autosaves-periodically ()
  "recentf-autosave-interval (Emacs 31) saves the recent-files list every 5
minutes, not just on a clean exit."
  (let ((custom (init-test--use-package-section 'recentf :custom)))
    (should (member '(recentf-autosave-interval 300) custom))))

(ert-deftest init-test/given-the-minibuffer-then-cursor-intangible-mode-is-armed ()
  "The cursor-intangible property in minibuffer-prompt-properties is inert
without the mode that honors it, so it is added to minibuffer-setup-hook."
  (should (init-test--declares '(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))))

(ert-deftest init-test/given-a-bookmark-then-set-is-on-C-c-b-m-and-jump-on-C-c-b-j ()
  "The C-c b bookmark prefix splits make/set (m) from jump (j → consult-bookmark)."
  (should (init-test--declares '(keymap-global-set "C-c b m" #'bookmark-set)))
  (should (init-test--declares '("C-c b j" . consult-bookmark))))

(ert-deftest init-test/given-a-bookmark-then-list-is-on-C-c-b-l ()
  "The C-c b bookmark prefix's list command (l → bookmark-bmenu-list)."
  (should (init-test--declares '(keymap-global-set "C-c b l" #'bookmark-bmenu-list))))

(ert-deftest init-test/given-the-config-then-C-c-e-m-edits-init-and-C-c-e-M-reloads-it ()
  "The C-c e config prefix splits edit (m, lowercase) from reload (M, uppercase)."
  (should (init-test--declares '(keymap-global-set "C-c e m" #'my-edit-init-file)))
  (should (init-test--declares '(keymap-global-set "C-c e M" #'my-reload-init-file)))
  (should (init-test--declares '(find-file (expand-file-name "init.el" user-emacs-directory))))
  (should (init-test--declares '(load-file (expand-file-name "init.el" user-emacs-directory)))))

(ert-deftest init-test/given-the-config-then-the-extras-menu-load-is-commented-out ()
  "The per-language loaders used to sit at the bottom of init.el itself;
they now live in extras.el, which init.el would load unconditionally --
but that (load ...) call is itself commented out right now, so extras.el
is not reached regardless of what is live inside it. Uncommenting this one
line in init.el is the only edit needed to turn the whole menu back on."
  (should-not (init-test--declares
               '(load (expand-file-name "extras.el" user-emacs-directory) :noerror :nomessage)))
  (should (with-temp-buffer
            (insert-file-contents (init-test-file "init.el"))
            (goto-char (point-min))
            (re-search-forward
             "^;; (load (expand-file-name \"extras\\.el\" user-emacs-directory) :noerror :nomessage)$"
             nil t))))

;;; ------------------------------------------------------------ project
(ert-deftest init-test/given-non-vc-projects-then-project-vc-extra-root-markers-are-set ()
  "Without a .git marker, project.el falls back to buffer directory and misroots
eglot; extra root markers recognize uninitialized project trees."
  (should (init-test--declares
           '(project-vc-extra-root-markers
             '("package.json" "tsconfig.json" "jsconfig.json" "deno.json" "deno.jsonc" "bunfig.toml"
               "pyproject.toml" "setup.py" "setup.cfg" "requirements.txt" "Pipfile"
               "Cargo.toml"
               "go.mod" "go.work"
               "pom.xml" "build.gradle" "build.gradle.kts" "settings.gradle" "settings.gradle.kts" "gradlew" "mvnw"
               "deps.edn" "project.clj" "shadow-cljs.edn" "build.boot"
               "CMakeLists.txt" "compile_commands.json" "meson.build"
               "mix.exs"
               "rebar.config" "erlang.mk"
               "cabal.project" "stack.yaml" "package.yaml" "*.cabal"
               "Gemfile" "Rakefile" "*.gemspec"
               "build.zig" "build.zig.zon"
               "superbol.toml"
               "cpanfile" "Makefile.PL" "Build.PL" "dist.ini"
               "guix.scm" "manifest.scm" "akku.manifest")))))

;;; ------------------------------------------------------------ eglot / flymake
(ert-deftest init-test/given-a-lisp-buffer-then-eglot-is-skipped ()
  "Hooking eglot-ensure onto prog-mode nags \"Cannot find suitable server\" in
every elisp buffer (no LSP here); my-eglot-ensure skips lisp-data-mode descendants."
  (should (init-test--declares '(unless (derived-mode-p 'lisp-data-mode)
                                  (eglot-ensure)))))

(ert-deftest init-test/given-eglot-then-its-event-log-is-disabled-for-perf ()
  "Logging every LSP event is a measurable drag; the events buffer is sized to 0."
  (should (init-test--declares '(eglot-events-buffer-config '(:size 0 :format full)))))

(ert-deftest init-test/given-eglot-then-its-commands-sit-under-a-buffer-local-prefix ()
  "eglot's own mode-map starts nearly empty (only the eldoc remap); its
commands are bound directly under C-c, sharing three prefixes with existing
commands: r with consult-ripgrep (relocated to r g) hosts rename/rewrite
(r n/r w); e with expreg/edit-init (e e/e m/e M) hosts extract (e x); l with
org-store-link hosts list-connections (l c). l alone is unreachable as a
direct command while eglot-mode is active -- the same trade-off as r and e.
eglot-code-actions has no raw C-c binding at all; it's only reachable via
M-RET or the leader's r a."
  (dolist (binding '(("C-c r n" . eglot-rename)
                      ("C-c f o" . eglot-format-buffer)
                      ("C-c o i" . eglot-code-action-organize-imports)
                      ("C-c i n" . eglot-code-action-inline)
                      ("M-RET"   . eglot-code-actions)
                      ("C-c e x" . eglot-code-action-extract)
                      ("C-c r w" . eglot-code-action-rewrite)
                      ("C-c q"   . eglot-code-action-quickfix)
                      ("C-c d"   . eglot-find-declaration)
                      ("C-c I"   . eglot-find-implementation)
                      ("C-c t"   . eglot-find-typeDefinition)
                      ("C-c R"   . eglot-reconnect)
                      ("C-c S"   . eglot-shutdown-all)
                      ("C-c l c" . eglot-list-connections)
                      ("C-c L"   . eglot-events-buffer)))
    (should (init-test--declares binding))))

(ert-deftest init-test/given-eglot-then-c-a-is-not-a-raw-binding ()
  "eglot-code-actions previously had a raw C-c c a binding that clobbered
C-c c (org-capture); it was removed entirely rather than kept around, since
M-RET and the leader's r a already cover it."
  (should-not (init-test--declares '("C-c c a" . eglot-code-actions))))

(ert-deftest init-test/given-the-leader-nav-keys-then-flymake-jumps-are-autoloaded ()
  "flymake is not preloaded and its nav commands carry no autoload cookie, so
:commands makes SPC , e / SPC . e resolvable anywhere."
  (should (init-test--declares '(flymake-goto-next-error flymake-goto-prev-error))))

(ert-deftest init-test/given-flymake-then-navigation-and-diagnostics-are-bound ()
  "Flymake binds M-n/M-p for error navigation and C-c f d for buffer diagnostics."
  (dolist (binding '(("M-n" . flymake-goto-next-error)
                     ("M-p" . flymake-goto-prev-error)
                     ("C-c f d" . flymake-show-buffer-diagnostics)))
    (should (init-test--declares binding))))

(ert-deftest init-test/given-an-elisp-buffer-then-flymake-uses-byte-compile-not-checkdoc ()
  "Elisp buffers get no eglot, so my-elisp-flymake turns on the built-in
byte-compile backend.  checkdoc is removed BEFORE enabling: flymake collects
backends at enable time and a since-removed backend never clears its stale report."
  (should (init-test--declares '(remove-hook 'flymake-diagnostic-functions
                                             #'elisp-flymake-checkdoc t)))
  (should (init-test--declares '(flymake-mode 1))))

(ert-deftest init-test/given-emacs-30-then-the-whole-config-dir-is-trusted-content ()
  "The byte-compile backend runs macro code, so Emacs 30 gates it behind
trusted-content.  user-init-file is trusted implicitly; the rest of the config
dir (early-init.el, extras/*.el) is trusted explicitly so it lints too."
  (should (init-test--declares
           '(trusted-content
             (list (abbreviate-file-name (file-truename user-emacs-directory)))))))

(ert-deftest init-test/given-a-diagnostic-then-it-shows-inline-at-end-of-line ()
  "IDE-style: diagnostics render inline at end of line, showing only the
most severe one per line to keep it compact."
  (should (init-test--declares '(flymake-show-diagnostics-at-end-of-line 'short))))

(ert-deftest init-test/given-a-flymake-error-jump-then-comma-dot-repeat ()
  "After one SPC . e / SPC , e jump, keep tapping . / , — the entry keys are
not in the repeat map, so repeat-check-key must be off."
  (should (init-test--declares '(put 'flymake-goto-next-error 'repeat-check-key 'no)))
  (should (init-test--declares '(put 'flymake-goto-prev-error 'repeat-check-key 'no))))

;;; ------------------------------------------------------------------- org
(ert-deftest init-test/given-org-then-its-reading-and-editing-niceties-are-set ()
  "visual-line wraps long lines; startup-indented fakes headline indent
(this is what turns on org-indent-mode); RET follows links; emphasis markers
hide; and edits inside folded text warn instead of silently corrupting."
  (should (init-test--declares '(org-mode . visual-line-mode)))
  (should (init-test--declares '(org-startup-indented t)))
  (should (init-test--declares '(org-return-follows-link t)))
  (should (init-test--declares '(org-hide-emphasis-markers t)))
  (should (init-test--declares '(org-catch-invisible-edits 'show-and-error))))

(ert-deftest init-test/given-org-then-org-directory-is-created-if-missing ()
  "org-directory is only a path, not auto-created by Org itself; without
this, a fresh ~/org missing on disk would break the first org-capture or
org-agenda call. Deferred behind eval-after-load like the rest of :config,
same as flymake.el's own keymap setup -- fires once org.el actually loads,
not necessarily at startup."
  (let ((config (init-test--use-package-section 'org :config)))
    (should (member '(unless (file-directory-p org-directory)
                       (make-directory org-directory t))
                    config))))

(ert-deftest init-test/given-org-then-babel-loads-more-than-just-elisp ()
  "org-babel-load-languages defaults to emacs-lisp only; without adding
python/shell here, #+begin_src blocks in those languages would not
execute at all."
  (should (init-test--declares
           '(org-babel-load-languages '((emacs-lisp . t) (python . t) (shell . t))))))

(ert-deftest init-test/given-org-then-capture-has-a-task-and-a-journal-template ()
  "org-capture-templates is unset by default, leaving C-c c with only Org's
single generic fallback; a task (file+headline) and journal
(file+olp+datetree, not the deprecated file+datetree) template make C-c c
actually usable."
  (should (init-test--declares
           '(org-capture-templates
             `(("t" "Task" entry (file+headline ,(expand-file-name "tasks.org" org-directory) "Tasks")
                "* TODO %?\n%U\n%a\n" :empty-lines 1)
               ("j" "Journal" entry (file+olp+datetree ,(expand-file-name "journal.org" org-directory))
                "* %U %?\n" :empty-lines 1))))))

;;; -------------------------------------------------------------------- avy
(ert-deftest init-test/given-avy-then-its-lead-face-matches-ideameow-overlay-color ()
  "Same #2ECC71/#ffffff as ideameow's .ideameowrc overlay-color/overlay-text-color."
  (should (init-test--declares '(set-face-attribute 'avy-lead-face nil
                                                     :background "#2ECC71"
                                                     :foreground "#ffffff"))))

;;; ------------------------------------------------------------- expreg
(ert-deftest init-test/given-expreg-then-M-r-grows-and-M-R-shrinks ()
  "M- stays reachable in the terminal via the ESC prefix; M-R shrinks a step."
  (should (init-test--declares '("M-r" . expreg-expand)))
  (should (init-test--declares '("M-R" . expreg-contract))))

(ert-deftest init-test/given-expreg-then-dot-comma-repeat-with-check-key-off ()
  "After any expreg command tap . to grow / , to shrink.  The entry keys
(M-r, C-c e e, M-R) are not in the repeat map, so repeat-check-key is disabled."
  (should (init-test--declares '(put 'expreg-expand   'repeat-check-key 'no)))
  (should (init-test--declares '(put 'expreg-contract 'repeat-check-key 'no))))

;;; ---------------------------------------------------- completion stack
(ert-deftest init-test/given-completion-then-orderless-leads-with-file-partials ()
  "orderless is the primary style (basic as fallback); files also get
partial-completion so foo/bar expands path segments."
  (should (init-test--declares '(completion-styles '(orderless basic))))
  (should (init-test--declares
           '(completion-category-overrides '((file (styles partial-completion)))))))

(ert-deftest init-test/given-consult-results-then-angle-bracket-narrows ()
  "Type < then a group key to narrow the candidate list to one group.  consult
reads this itself, so it is the one consult setting that belongs in :config."
  (should (member '(setq consult-narrow-key "<")
                  (init-test--use-package-section 'consult :config))))

(ert-deftest init-test/given-xref-then-consult-drives-its-pickers ()
  ":init, not :config — :bind defers consult, so in :config the first xref jump
of a session would still get the stock *xref* buffer."
  (should (member '(setq xref-show-xrefs-function #'consult-xref
                         xref-show-definitions-function #'consult-xref)
                  (init-test--use-package-section 'consult :init))))

(ert-deftest init-test/given-register-preview-then-consult-renders-it ()
  "Also :init: both functions are autoloaded, so advising eagerly costs no
startup load, while advising from :config would leave the first C-x r j of a
session with the stock preview at the stock one-second delay."
  (let ((eager (init-test--use-package-section 'consult :init)))
    (should (member '(advice-add #'register-preview
                                 :override #'consult-register-window)
                    eager))
    (should (member '(setq register-preview-delay 0.5) eager))))

(ert-deftest init-test/given-a-prefix-key-then-embark-shows-the-bindings ()
  (should (init-test--declares '(setq prefix-help-command #'embark-prefix-help-command))))

(ert-deftest init-test/given-embark-consult-glue-then-it-loads-lazily ()
  ":after keeps this glue lazy — a bare declaration would drag embark AND
consult in at startup."
  (should (init-test--declares '(:after (embark consult)))))

(ert-deftest init-test/given-corfu-then-history-persists-through-savehist ()
  "corfu-history is added to savehist so completion ordering survives restarts."
  (should (init-test--declares '(add-to-list 'savehist-additional-variables 'corfu-history))))

(ert-deftest init-test/given-an-eglot-buffer-then-cape-supers-the-capfs ()
  "While eglot manages a buffer, its completions and dabbrev's arrive merged as
one capf, ahead of everything else in the buffer."
  (should (init-test--declares '(add-hook 'eglot-managed-mode-hook #'my-eglot-capfs)))
  (should (init-test--declares
           '(cape-capf-super #'eglot-completion-at-point #'cape-dabbrev))))

(ert-deftest init-test/given-eglot-stops-managing-then-the-mode-keeps-its-own-capf ()
  "eglot-managed-mode-hook fires on disable too, so my-eglot-capfs must add and
remove ONLY its own capf.  Replacing the whole buffer-local list and killing it
on the way out also discards the major mode's capf — after an eglot-shutdown the
buffer would silently drop to the global capfs, with no
python-completion-at-point (or elisp-, or any other) left."
  (init-test--eval-section-def 'cape :preface 'defun 'my-eglot-capf)
  (init-test--eval-section-def 'cape :preface 'defun 'my-eglot-capfs)
  (with-temp-buffer
    (add-hook 'completion-at-point-functions #'ignore nil t)
    (let ((mode-capfs completion-at-point-functions))
      (cl-letf (((symbol-function 'eglot-managed-p) (lambda () t)))
        (my-eglot-capfs))
      (should (memq 'my-eglot-capf completion-at-point-functions))
      (should (memq 'ignore completion-at-point-functions))
      (cl-letf (((symbol-function 'eglot-managed-p) (lambda () nil)))
        (my-eglot-capfs))
      (should-not (memq 'my-eglot-capf completion-at-point-functions))
      (should (equal completion-at-point-functions mode-capfs)))))

;;; ------------------------------------------------------------- ace-window
(ert-deftest init-test/given-other-window-then-ace-window-remaps-it-frame-scoped ()
  "ace-window labels each window and jumps by key (this also powers C-c w w);
scoped to the current frame."
  (should (init-test--declares '([remap other-window] . ace-window)))
  (should (init-test--declares '(aw-scope 'frame))))

(ert-deftest init-test/given-ace-window-then-its-hint-is-green-without-a-background ()
  "ace-window draws C-c w w and C-c w r hints with its own `aw-leading-char-face',
which defaults to plain red and inherits nothing from avy — so it needs its own
green.  It must stay FOREGROUND-only: `aw--overlay-str' appends a newline when
the hint lands at end of line, and a newline inside a display string makes Emacs
pad the rest of the line with the face, turning any background into a
full-width bar."
  (should (init-test--declares '(set-face-attribute 'aw-leading-char-face nil
                                                     :background 'unspecified
                                                     :foreground "#2ECC71"
                                                     :weight 'bold))))

;;; --------------------------------------------------------------- diff-hl
(ert-deftest init-test/given-diff-hl-then-it-is-demanded-eagerly ()
  ":hook alone defers diff-hl and the global mode never turns on at startup;
:demand t forces it eager."
  (should (init-test--declares '(diff-hl-update-async t))))

(ert-deftest init-test/given-a-diff-hl-hunk-jump-then-dot-comma-repeat ()
  "SPC . c / SPC , c mirror the C-x v ] / [ hunk nav; . and , are added to the
command map and check-key is off because the keypad's final key `c' is not a member."
  (should (init-test--declares '(keymap-set diff-hl-command-map "." #'diff-hl-next-hunk)))
  (should (init-test--declares '(keymap-set diff-hl-command-map "," #'diff-hl-previous-hunk)))
  (should (init-test--declares '(put 'diff-hl-next-hunk 'repeat-check-key 'no)))
  (should (init-test--declares '(put 'diff-hl-previous-hunk 'repeat-check-key 'no))))

(ert-deftest init-test/given-a-terminal-frame-then-diff-hl-draws-in-the-margin ()
  "A tty has no fringe, so diff-hl falls back to the margin there."
  (should (init-test--declares '(unless (display-graphic-p)
                                  (diff-hl-margin-mode 1)))))

;;; ------------------------------------------------------- corfu-terminal
(ert-deftest init-test/given-corfu-terminal-then-it-defers-until-a-tty-needs-it ()
  "Its :init only calls the autoloaded mode, and only in a tty, so :defer t
is what keeps corfu-terminal itself out of a GUI startup."
  (should (member t (init-test--use-package-section 'corfu-terminal :defer))))

(ert-deftest init-test/given-a-terminal-then-corfu-popups-render-in-tty ()
  "Emacs 30 can't draw child frames in a tty, so corfu-terminal-mode takes over."
  (should (init-test--declares '(unless (display-graphic-p)
                                  (corfu-terminal-mode 1)))))

;;; --------------------------------------------------------------- wgrep
(ert-deftest init-test/given-wgrep-then-it-defers-until-a-grep-buffer-needs-it ()
  "A block with only :init/:custom/:config has no defer trigger, so use-package
would require wgrep at startup; :commands defers it instead -- its entry
command has no autoload of its own, so grep buffers and embark's export both
reach it through the autoloaded wgrep-setup."
  (should (member '(wgrep-change-to-wgrep-mode)
                  (init-test--use-package-section 'wgrep :commands))))

;;; init-tests.el ends here
