;; no GC while we're starting up. init.el puts it back to normal afterwards.  -*- lexical-binding: t; -*-
(setq gc-cons-threshold most-positive-fixnum)

;; don't reflow the frame when the menu bar or font changes, it just slows startup
(setq frame-inhibit-implied-resize t)

;; load a fresh .el over a stale .elc
(setq load-prefer-newer t)

;; leave my config alone, ignore X resources
(setq inhibit-x-resources t)

;; no splash screen
(setq inhibit-startup-screen t)
;; The "For information about GNU Emacs..." echo-area line can't be silenced via
;; inhibit-startup-echo-area-message: Emacs only honors that variable when init.el
;; *literally* contains (setq inhibit-startup-echo-area-message "<login>") or it's
;; set through Customize (an anti-spoofing check in startup.el) — assigning
;; user-login-name matches neither, and early-init.el isn't even scanned. Neuter
;; the function that prints it instead.
(fset 'display-startup-echo-area-message #'ignore)

;; strip the toolbar/scrollbar/menubar before the first frame paints, otherwise it flickers
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)

;; keep native-comp quiet and compile packages when they install
(setq native-comp-async-report-warnings-errors 'silent
      package-native-compile t)
