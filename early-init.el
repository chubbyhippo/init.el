;;; early-init.el --- startup hygiene  -*- lexical-binding: t; -*-
(setq gc-cons-threshold most-positive-fixnum)

(setq frame-inhibit-implied-resize t)

(setq load-prefer-newer t)

(setq inhibit-x-resources t)

(setq inhibit-startup-screen t)
(fset 'display-startup-echo-area-message #'ignore)

(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)

(setq native-comp-async-report-warnings-errors 'silent
      package-native-compile t)
