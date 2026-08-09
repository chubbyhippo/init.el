;;; perl.el --- Perl development extras  -*- lexical-binding: t; -*-

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

;; Optional Perl layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. Handles .pl / .pm /
;; .t / .pod and `#!…perl' scripts — Emacs already maps those to perl-mode.
;;
;; Everything here is built in. There is no perl-ts-mode in Emacs 30, and no
;; standard DAP adapter worth wiring through dape (same situation as Erlang).
;; You supply the external tools:
;;   - Perl itself on PATH
;;   - Perl::LanguageServer (`cpanm Perl::LanguageServer`, or your distro's
;;     package) — eglot's own table already maps perl-mode/cperl-mode to
;;     `perl -MPerl::LanguageServer -e Perl::LanguageServer::run`, so nothing
;;     to register here; eglot attaches via init.el's prog-mode hook once the
;;     module loads
;;   - optional: perltidy on PATH for project format hooks / compile recipes
;;
;; Debugging is the built-in gud frontend: M-x perldb. No dape config is
;; added on purpose.
;;
;; ELPA-only: nothing — cperl-mode, perl-mode, eglot, and perldb are all in
;; Emacs. (pls / PerlNavigator / sepia / etc. are outside GNU/NonGNU ELPA or
;; are alternate servers you can point eglot at yourself via
;; eglot-server-programs if you prefer them over Perl::LanguageServer.)

;;; Built-in
;; Prefer cperl-mode over the classic perl-mode. Emacs binds .pl/.pm/… to
;; perl-mode; a remap is enough — no auto-mode-alist fiddling. cperl-mode
;; still derives from prog-mode, so eglot keeps attaching.
(use-package cperl-mode
  :ensure nil
  :init
  (add-to-list 'major-mode-remap-alist '(perl-mode . cperl-mode))
  :custom
  ;; Match common Perl style (perlstyle.pod): 4-space indent, hanging open
  ;; paren blocks, closing paren pulled back. Tune per-project with .dir-locals
  ;; if a codebase disagrees.
  (cperl-indent-level 4)
  (cperl-continued-statement-offset 4)
  (cperl-close-paren-offset -4)
  (cperl-indent-parens-as-block t)
  (cperl-tab-always-indent t)
  ;; '_' in identifiers is not "invalid trailing whitespace".
  (cperl-invalid-face nil))
;;; End Built-in

;; No dape block: Perl has no standard DAP adapter in this config's ELPA set.
;; Use M-x perldb (gud). Builds/tests go through M-x project-compile / compile
;; (`prove', `make test', etc.).

;; `perl' is a free, specific feature name — no built-in file or ELPA package
;; provides it (Emacs's own modes live in perl-mode.el / cperl-mode.el, which
;; provide `perl-mode' / `cperl-mode'); this file is loaded by path from
;; init.el, so this is a courtesy, not a requirement. (Same reasoning as
;; ruby.el / rust.el / zig.el.)
(provide 'perl)
;;; perl.el ends here
