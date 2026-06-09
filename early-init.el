;; Raise the GC ceiling during startup so it doesn't collect mid-load.
;; It is lowered again after startup in init.el (emacs-startup-hook).
(setq gc-cons-threshold most-positive-fixnum)

;; Don't resize the frame when the menu bar / font changes — saves startup time.
(setq frame-inhibit-implied-resize t)

;; Prefer a newer .el to a stale .elc.
(setq load-prefer-newer t)

;; Don't let X resources override the config.
(setq inhibit-x-resources t)

;; Skip the splash screen.
(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name)

;; Drop UI chrome BEFORE the first frame is drawn (no flicker).
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)

;; Quieter, eager native compilation.
(setq native-comp-async-report-warnings-errors 'silent
      package-native-compile t)
