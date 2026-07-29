;;; cobol.el --- COBOL development extras  -*- lexical-binding: t; -*-

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

;; Optional COBOL layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. Handles .cob / .cbl /
;; .cpy / .cbx — and their upcased mainframe spellings, since `auto-mode-case-fold'
;; makes Emacs retry auto-mode-alist case-insensitively.
;;
;; Like haskell, the major mode is NOT built in — but unlike haskell it comes from
;; GNU ELPA: cobol-mode 1.1 (Edward Hart, FSF copyright), the only COBOL mode on
;; either archive. Know before adopting it: upstream declares itself ORPHANED in
;; its own News section ("we're looking for a generous soul willing to give it
;; loving care"), and 1.1 dates from 2024-03-31.
;;
;; There is NO tree-sitter path — the one extra where that is not a "yet". Emacs
;; 30 ships no cobol grammar integration, and no cobol-ts-mode exists on either
;; archive; a community grammar (yutaro-sakamoto/tree-sitter-cobol) exists but no
;; Emacs mode consumes it. Highlighting is cobol-mode's own regexp +
;; `syntax-propertize' work, which is also why the source format below is
;; load-bearing.
;;
;; You supply the external tools:
;;   - GnuCOBOL — `cobc' / `cobcrun'. `sudo apt install gnucobol' pulls
;;     gnucobol3 3.2, which is also the floor the LSP server needs, and is what
;;     wsl-ubuntu-settings' init-el-extras.sh installs. Compiles run through
;;     M-x project-compile / compile.
;;   - superbol-free, the SuperBOL LSP server (OCamlPro, MIT) — definitions,
;;     references, hover on copybooks, semantic tokens, and FIXED/FREE
;;     formatting, configured per project by a `superbol.toml' at its root.
;;     eglot has NO COBOL entry, so this layer registers one, borrowing the
;;     invocation from SuperBOL's own eglot glue.
;;     It is not packaged anywhere: no opam package, and the 1.0.0 release ships
;;     no binaries (its VSIX bundles the server as JavaScript), so it has to be
;;     built from source — the recipe is in wsl-ubuntu-settings' README.
;;
;; WHY THE eglot HOOK IS GUARDED. cobol-mode derives from prog-mode, so init.el's
;; global `my-eglot-ensure' fires in every COBOL buffer — and both ways of
;; getting it wrong pop a *Warnings* buffer on every file you open (measured on
;; Emacs 30.2):
;;   no server registered      Wrong type argument: processp, nil
;;   registered, not on PATH   Searching for program: ... superbol-free
;; So the advice below skips eglot in COBOL buffers until superbol-free is
;; actually executable: compiler-only editing stays silent, and building the
;; server later turns the LSP on with no edit here. scheme.el uses the same
;; advice unconditionally — Scheme has no LSP at all, whereas COBOL's merely has
;; to be built. This is html.el's problem mirrored: there the prog-mode hook
;; never reaches the mode, here it reaches a mode with nothing behind it.
;;
;; NO debug adapter. dape ships no COBOL config, and the GnuCOBOL debugger is
;; superbol-vscode-debug — a VS Code extension wrapping gdb over the C that cobc
;; generates, not a standalone adapter dape can launch. Same gap as erlang and
;; haskell; debug with `cobc -g' plus M-x gdb, or GnuCOBOL's own runtime trace.
;;
;; FIXED vs FREE format. `cobol-source-format' is set below because it decides
;; highlighting, indentation AND the syntax-propertize rules: fixed-85 means a
;; sequence area in columns 1-6, the indicator in 7, Area A at 8, and everything
;; past 72 ignored. Set it to `free' for free-format code. It is declared :safe,
;; so a .dir-locals.el entry works per project, but upstream's Known Bugs warn
;; that switching mid-session does not fully take — restart Emacs after changing
;; it. `M-x cobol-column-ruler' shows the areas for the current format.
;;
;; cobol-mode binds no keys of its own beyond remapping `back-to-indentation'
;; (M-m) to a format-aware version that lands on the code area rather than
;; column 0 — so its formatting commands are M-x only: `cobol-format-buffer' /
;; `cobol-format-region' case the source per `cobol-format-style', and the COBOL
;; menu holds the division/statement skeletons.
;;
;; Completion: upstream's Commentary recommends auto-complete-mode, which is
;; MELPA-only and superseded here — corfu + cape-dabbrev already complete the
;; long COBOL keywords, and eglot's capf joins in once superbol-free runs.
;;
;; ELPA-only: cobol-mode is on GNU ELPA; eglot is built in. There is no second
;; candidate to weigh — SuperBOL's own Emacs mode (cobol-superbol-mode.el, a fork
;; of this one) is distributed by wget into ~/.emacs.d/lisp/, on no archive at
;; all, so only its one-line server registration is borrowed here.

;;; GNU ELPA
(use-package cobol-mode
  :ensure t
  ;; The package registers no file extensions itself — its autoload cookie
  ;; covers only the mode function — so the associations are this layer's job.
  ;; .cbx comes from SuperBOL's default extension set; upstream suggests the
  ;; other three.
  :mode ("\\.cob\\'" "\\.cbl\\'" "\\.cpy\\'" "\\.cbx\\'")
  :custom
  ;; `free' for free-format source; see the header on why this cannot be
  ;; flipped in a running session.
  (cobol-source-format 'fixed-85))

;; Deliberately at top level, not in the use-package `:config' above: that is
;; wrapped in `eval-after-load' for the package, so eglot would not learn the
;; server until a COBOL file had already opened.  The invocation is SuperBOL's
;; own, from its eglot-superbol.el, rekeyed onto the ELPA mode.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(cobol-mode . ("superbol-free" "lsp"))))

;; Hold init.el's prog-mode eglot hook back until the server exists (see the
;; header). Guarded on `fboundp' so load order does not matter, and named so it
;; coexists with scheme.el's advice on the same function.
(when (fboundp 'my-eglot-ensure)
  (advice-add 'my-eglot-ensure :before-while
              (lambda () (or (not (derived-mode-p 'cobol-mode))
                             (executable-find "superbol-free")))
              '((name . my-cobol--skip-eglot-until-superbol))))
;;; End GNU ELPA

(provide 'cobol)
;;; cobol.el ends here
