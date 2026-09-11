;;; haskell-tests.el --- ERT suite for extras/haskell.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/haskell.el (moved here when that file's
;; comments were stripped, so the rationale below still documents the tests
;; that pin its behavior down):
;;
;; Optional Haskell layer for init.el. Disabled by default — uncomment the
;; matching loader in extras.el to enable it. Handles .hs / .lhs
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
;;
;; interactive-haskell-mode binds M-. to its GHCi tags jump, which would
;; shadow the global M-. in every Haskell buffer. With HLS running, eglot's
;; xref is the better answer, so the key is handed back to it in :config.
;; The map lives in the package's haskell.el, NOT in haskell-mode.el, so it is
;; still undefined when :config runs — `with-eval-after-load' waits for that
;; file. This is also why the no-provide rule (see below) is load-bearing
;; rather than tidiness: were the file to provide `haskell', the hook would
;; fire immediately against an undefined map and the real library would never
;; load at all.
;;
;; No `(provide 'haskell)' in the extras file — haskell-mode's own haskell.el
;; owns the `haskell' feature, so providing it there would make that library
;; look already-loaded.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ============================================================== haskell.el
(ert-deftest extras-test/given-haskell-then-interactive-haskell-mode-hooks-into-haskell-mode ()
  (should (member '(haskell-mode . interactive-haskell-mode)
                  (extras-test--use-package-section "haskell.el" 'haskell-mode :hook)))
  (should (member '(haskell-process-type 'auto)
                  (extras-test--use-package-section "haskell.el" 'haskell-mode :custom))))

(ert-deftest extras-test/given-haskell-then-M-dot-is-handed-back-to-eglot ()
  (should (extras-test--declares "haskell.el"
                                  '(keymap-unset interactive-haskell-mode-map "M-." t))))

(provide 'haskell-tests)
;;; haskell-tests.el ends here
