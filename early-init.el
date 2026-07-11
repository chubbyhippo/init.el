;; no GC while we're starting up. init.el puts it back to normal afterwards.  -*- lexical-binding: t; -*-
(setq gc-cons-threshold most-positive-fixnum)

;; don't reflow the frame when the menu bar or font changes, it just slows startup
(setq frame-inhibit-implied-resize t)

;; load a fresh .el over a stale .elc
(setq load-prefer-newer t)

;; leave my config alone, ignore X resources
(setq inhibit-x-resources t)

;; no splash screen
(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name)

;; strip the toolbar/scrollbar/menubar before the first frame paints, otherwise it flickers
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)

;; keep native-comp quiet and compile packages when they install
(setq native-comp-async-report-warnings-errors 'silent
      package-native-compile t)
