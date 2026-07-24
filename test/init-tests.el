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
  (should (init-test--declares '(setq gc-cons-threshold (* 16 1024 1024)))))

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

(ert-deftest init-test/given-customize-then-its-writes-go-to-a-separate-file ()
  "M-x customize saves are redirected to custom.el so they never rewrite this
hand-curated init.el."
  (should (init-test--declares '(setq custom-file (locate-user-emacs-file "custom.el"))))
  (should (init-test--declares '(load custom-file 'noerror))))

(ert-deftest init-test/given-the-minibuffer-then-cursor-intangible-mode-is-armed ()
  "The cursor-intangible property in minibuffer-prompt-properties is inert
without the mode that honors it, so it is added to minibuffer-setup-hook."
  (should (init-test--declares '(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))))

(ert-deftest init-test/given-a-bookmark-then-set-is-on-C-c-b-m-and-jump-on-C-c-b-j ()
  "The C-c b bookmark prefix splits make/set (m) from jump (j → consult-bookmark)."
  (should (init-test--declares '(keymap-global-set "C-c b m" #'bookmark-set)))
  (should (init-test--declares '("C-c b j" . consult-bookmark))))

;;; ------------------------------------------------------------ eglot / flymake
(ert-deftest init-test/given-a-lisp-buffer-then-eglot-is-skipped ()
  "Hooking eglot-ensure onto prog-mode nags \"Cannot find suitable server\" in
every elisp buffer (no LSP here); my-eglot-ensure skips lisp-data-mode descendants."
  (should (init-test--declares '(unless (derived-mode-p 'lisp-data-mode)
                                  (eglot-ensure)))))

(ert-deftest init-test/given-eglot-then-its-event-log-is-disabled-for-perf ()
  "Logging every LSP event is a measurable drag; the events buffer is sized to 0."
  (should (init-test--declares '(eglot-events-buffer-config '(:size 0 :format full)))))

(ert-deftest init-test/given-the-leader-nav-keys-then-flymake-jumps-are-autoloaded ()
  "flymake is not preloaded and its nav commands carry no autoload cookie, so
:commands makes SPC , e / SPC . e resolvable anywhere."
  (should (init-test--declares '(flymake-goto-next-error flymake-goto-prev-error))))

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
  "IDE-style: the most severe diagnostic is rendered inline at end of line."
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

;;; ------------------------------------------------------------- expreg
(ert-deftest init-test/given-expreg-then-M-r-grows-and-M-R-shrinks ()
  "M- stays reachable in the terminal via the ESC prefix; M-R shrinks a step."
  (should (init-test--declares '("M-r" . expreg-expand)))
  (should (init-test--declares '("M-R" . expreg-contract))))

(ert-deftest init-test/given-expreg-then-dot-comma-repeat-with-check-key-off ()
  "After any expreg command tap . to grow / , to shrink.  The entry keys
(M-r, C-c e, M-R) are not in the repeat map, so repeat-check-key is disabled."
  (should (init-test--declares '(put 'expreg-expand   'repeat-check-key 'no)))
  (should (init-test--declares '(put 'expreg-contract 'repeat-check-key 'no))))

;;; ---------------------------------------------------- completion stack
(ert-deftest init-test/given-completion-then-orderless-leads-with-file-partials ()
  "orderless is the primary style (basic as fallback); files also get
partial-completion so foo/bar expands path segments."
  (should (init-test--declares '(completion-styles '(orderless basic))))
  (should (init-test--declares
           '(completion-category-overrides '((file (styles partial-completion)))))))

(ert-deftest init-test/given-a-consult-jump-then-the-hit-is-recentered ()
  "Without this the jump target lands at the screen edge."
  (should (init-test--declares '(add-hook 'consult-after-jump-hook #'recenter))))

(ert-deftest init-test/given-consult-results-then-angle-bracket-narrows ()
  "Type < then a group key to narrow the candidate list to one group."
  (should (init-test--declares '(setq consult-narrow-key "<"))))

(ert-deftest init-test/given-xref-then-consult-drives-its-pickers ()
  (should (init-test--declares '(setq xref-show-xrefs-function #'consult-xref
                                      xref-show-definitions-function #'consult-xref))))

(ert-deftest init-test/given-register-preview-then-consult-renders-it ()
  (should (init-test--declares
           '(advice-add #'register-preview :override #'consult-register-window))))

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
  "eglot-managed-mode-hook fires on disable too, so my-eglot-capfs branches on
state: merged eglot+dabbrev capf while managed, and the buffer-local list is
dropped on exit — otherwise a serverless eglot capf is left behind and errors."
  (should (init-test--declares '(add-hook 'eglot-managed-mode-hook #'my-eglot-capfs)))
  (should (init-test--declares '(kill-local-variable 'completion-at-point-functions))))

;;; ------------------------------------------------------------- ace-window
(ert-deftest init-test/given-other-window-then-ace-window-remaps-it-frame-scoped ()
  "ace-window labels each window and jumps by key (this also powers C-c w w);
scoped to the current frame."
  (should (init-test--declares '([remap other-window] . ace-window)))
  (should (init-test--declares '(aw-scope 'frame))))

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

;;; ------------------------------------------------------- terminal / corfu tty
(ert-deftest init-test/given-a-terminal-then-corfu-popups-render-in-tty ()
  "Emacs 30 can't draw child frames in a tty, so corfu-terminal-mode takes over."
  (should (init-test--declares '(unless (display-graphic-p)
                                  (corfu-terminal-mode 1)))))

;;; init-tests.el ends here
