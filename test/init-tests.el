;;; init-tests.el --- BDD-style ERT suite for init.el  -*- lexical-binding: t; -*-

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

;;; ---------------------------------------------- bring the units to life
;; Evaluating the meow use-package block defines and calls my-meow-setup, which
;; populates meow's normal/motion state keymaps and the leader map
;; (mode-specific-map), and sets M-SPC globally.  The window/zoom keymaps and
;; the custom window commands are plain top-level forms.
(init-test--eval-def 'use-package 'meow)
(dolist (km '(my-window-map my-window-resize-map
              my-text-scale-repeat-map my-winner-repeat-map))
  (init-test--eval-def 'defvar-keymap km))
(dolist (fn '(my-text-scale-reset my-window-resize))
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

;;; ================================================= config invariants
(ert-deftest init-test/given-the-config-then-M-m-translates-to-C-c ()
  "The whole personal C-c map is reachable one-handed via M-m."
  (should (init-test--declares '(keymap-set key-translation-map "M-m" "C-c"))))

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

;;; init-tests.el ends here
