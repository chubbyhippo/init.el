;;; haskell.el --- Haskell development extras  -*- lexical-binding: t; -*-

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

;; Optional Haskell layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. Handles .hs / .lhs
;; plus the cabal files (.cabal, cabal.project, ~/.cabal/config).
;;
;; UNLIKE every other extra, the major mode is NOT built in: Emacs ships no
;; Haskell mode and no haskell tree-sitter integration, so the mode itself comes
;; from NonGNU ELPA. You supply the external tools:
;;   - GHC and cabal (or stack) — ghcup is the usual installer
;;   - haskell-language-server — nothing to wire here: eglot's built-in table
;;     already maps haskell-mode to ("haskell-language-server-wrapper" "--lsp"),
;;     and haskell-mode derives from prog-mode, so init.el's prog-mode hook
;;     attaches it as soon as the wrapper is on PATH
;;
;; NO debug adapter. dape ships no Haskell config, and haskell-debug-adapter is
;; MELPA/Hackage-only — so there is no DAP here, the same gap erlang.el has.
;; haskell-mode's own `haskell-debug' drives the GHCi debugger instead.
;;
;; Formatting is left to HLS (ormolu / fourmolu / stylish-haskell, whichever the
;; project configures) — no format-on-save imposed, as in cpp.el.
;;
;; ELPA-only: haskell-mode is on NonGNU ELPA. lsp-haskell, dante, ormolu, attrap
;; and hindent are MELPA-only, so they are not used here. haskell-ts-mode IS on
;; NonGNU ELPA but is deliberately not used: eglot's built-in server entry is
;; keyed on haskell-mode, and haskell-mode also brings the cabal modes and the
;; GHCi REPL, so using both would mean two Haskell modes for no gain.
;; consult-hoogle is on GNU ELPA if you ever want Hoogle search from consult.

;;; NonGNU ELPA
(use-package haskell-mode
  :ensure t
  :preface
  ;; Declared, not defined: the real defvar lives in haskell-mode's haskell.el.
  ;; This only tells the byte-compiler the symbol is special, so the reference
  ;; in :config below isn't flagged as a free variable.
  (defvar interactive-haskell-mode-map)
  :hook (haskell-mode . interactive-haskell-mode)
  :custom
  (haskell-process-type 'auto)
  (haskell-process-auto-import-loaded-modules t)
  (haskell-process-suggest-remove-import-lines t)
  :config
  ;; interactive-haskell-mode binds M-. to its GHCi tags jump, which would
  ;; shadow the global M-. in every Haskell buffer.  With HLS running, eglot's
  ;; xref is the better answer, so hand the key back to it.
  ;;
  ;; The map lives in the package's haskell.el, NOT in haskell-mode.el, so it is
  ;; still undefined when this :config runs — wait for that file.  This is also
  ;; why the no-provide rule below is load-bearing rather than tidiness: were
  ;; this file to provide `haskell', the hook would fire immediately against an
  ;; undefined map and the real library would never load at all.
  (with-eval-after-load 'haskell
    (keymap-unset interactive-haskell-mode-map "M-." t)))
;;; End NonGNU ELPA

;; No `(provide 'haskell)' — haskell-mode's own haskell.el owns the `haskell'
;; feature, so providing it here would make that library look already-loaded.
;; This file is loaded by path from init.el, so a provide isn't needed.
;;; haskell.el ends here
