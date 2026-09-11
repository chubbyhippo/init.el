;;; dotnet-tests.el --- ERT suite for extras/dotnet.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/dotnet.el (moved here when that file's
;; comments were stripped, so the rationale below still documents the tests
;; that pin its behavior down):
;;
;; Optional C# / .NET layer for init.el. Disabled by default -- uncomment
;; the matching loader in extras.el to enable it. Handles .cs (via
;; csharp-mode's own autoload-cookie auto-mode-alist entry) and .csx
;; (dotnet-script files, registered here since csharp-mode.el itself only
;; covers .cs).
;;
;; C#-ONLY, NOT F#/VB.NET. .NET as a platform also covers F# and VB.NET,
;; but neither has any GNU/NonGNU ELPA path at all: fsharp-mode,
;; eglot-fsharp, and the newer tree-sitter fsharp-ts-mode are ALL
;; MELPA-only (checked both official archives directly), so this config's
;; "never MELPA" rule leaves no ELPA-compatible way to add F# here. VB.NET
;; has no Emacs mode on any archive, MELPA included. C# is the only .NET
;; language with a fully built-in path, which is why this layer is scoped
;; to it alone.
;;
;; Most of the stack is built in: csharp-mode AND csharp-ts-mode have
;; shipped in Emacs core since Emacs 29 (the standalone
;; emacs-csharp/csharp-mode package was discontinued once it landed
;; in-tree) -- unlike java.el/go.el/rust.el, csharp-mode.el itself handles
;; the tree-sitter remap unconditionally at load time
;; (treesit-major-mode-remap-alist gets `(csharp-mode . csharp-ts-mode)'
;; with no :init block needed here), and calls `treesit-ensure-installed'
;; lazily the first time csharp-ts-mode actually runs -- so this layer
;; adds no treesit-language-source-alist wiring of its own, unlike every
;; other tree-sitter-backed extras file.
;;
;; csharp-mode derives from prog-mode (confirmed in Emacs core's
;; define-derived-mode call), so init.el's global prog-mode hook already
;; reaches it -- no missing-hook patch is needed here, unlike html.el/
;; yaml.el/markdown.el/xml.el's text-mode-derived majors.
;;
;; WHY THE eglot HOOK IS GUARDED. eglot ships NO built-in C# entry at all
;; (checked eglot-server-programs directly), so this layer registers one
;; itself, same situation as cobol.el/sql.el/kotlin.el/xml.el. Without a
;; guard, opening any .cs file would mean "Searching for program: ...
;; csharp-ls" in *Warnings* until the server is installed; the guard is the
;; shared `my-eglot-ensure-once-ready' helper from extras/eglot-ensure.el (pulled
;; in via `require' with an explicit file path), behaviorally tested once
;; in eglot-ensure-tests.el. `(derived-mode-p 'csharp-mode)' alone covers
;; csharp-ts-mode buffers too -- csharp-mode.el's own
;; `derived-mode-add-parents' call registers csharp-mode as
;; csharp-ts-mode's virtual parent.
;;
;; You supply the external tool: csharp-ls
;; (github.com/razzmatazz/csharp-language-server), a community,
;; Roslyn-based server (not Microsoft-affiliated) -- installed via
;; `dotnet tool install --global csharp-ls', which puts a plain
;; `csharp-ls' on PATH with no flags needed (it defaults to stdio).
;; Microsoft's own official Roslyn LSP server (the engine behind VS Code's
;; C# Dev Kit, now also available as the `roslyn-language-server' dotnet
;; tool) is NOT used here: there is no maintained Eglot integration for it
;; yet, and driving it well needs the same custom project/solution-loading
;; extensions VS Code's extension supplies, not just a bare LSP hookup.
;;
;; Debugging is entirely free: dape ships a BUILT-IN `netcoredbg' config
;; for `(csharp-mode csharp-ts-mode)' (checked dape.el's own dape-configs
;; alist directly) that finds the first bin/Debug/*/*.dll and launches
;; Samsung's netcoredbg against it -- so, unlike java.el's jdtls-debug-jar
;; wiring, this layer's own dape block is the same bare :commands/:custom
;; shape every other language layer uses; the only external tool left to
;; install yourself is netcoredbg itself (Samsung/netcoredbg releases, or
;; `winget install Samsung.NetCoreDbg' on Windows).
;;
;; ELPA-only: dape is on GNU ELPA; the major modes and eglot are built in.
;; (eglot-csharp -- the wrapper package that would auto-register csharp-ls
;; -- is not packaged on GNU ELPA, NonGNU ELPA, OR MELPA as of writing,
;; GitHub-source only, so this layer registers csharp-ls itself instead of
;; depending on it.)

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ================================================================ dotnet.el
(ert-deftest extras-test/given-dotnet-then-csx-maps-to-csharp-mode ()
  (should (member "\\.csx\\'"
                  (extras-test--use-package-section "dotnet.el" 'csharp-mode :mode))))

(ert-deftest extras-test/given-dotnet-then-eglot-learns-csharp-ls ()
  (let ((eglot-server-programs nil))
    (extras-test--eval-with-eval-after-load "dotnet.el" 'eglot)
    (should (equal (cdr (assoc '(csharp-mode csharp-ts-mode) eglot-server-programs))
                   '("csharp-ls")))))

(ert-deftest extras-test/given-dotnet-then-it-requires-the-shared-eglot-ensure-helper ()
  (should (extras-test--declares
           "dotnet.el"
           '(require 'eglot-ensure (expand-file-name "extras/eglot-ensure" user-emacs-directory)))))

(ert-deftest extras-test/given-dotnet-then-eglot-is-skipped-until-csharp-ls-exists ()
  "dotnet.el delegates the skip-until-binary advice to the shared
my-eglot-ensure-once-ready helper (behaviorally tested on its own in
eglot-ensure-tests.el) rather than hand-rolling it."
  (should (extras-test--declares
           "dotnet.el" '(my-eglot-ensure-once-ready 'csharp-mode "csharp-ls"))))

(ert-deftest extras-test/given-dotnet-then-dape-is-declared-with-no-language-specific-config ()
  "dape ships a built-in netcoredbg config for csharp-mode/csharp-ts-mode,
so unlike java.el this layer needs no :config block of its own."
  (should (extras-test--declares "dotnet.el" '(dape dape-breakpoint-toggle))))

(ert-deftest extras-test/given-dotnet-then-it-provides-dotnet ()
  (should (extras-test--declares "dotnet.el" '(provide 'dotnet))))

(provide 'dotnet-tests)
;;; dotnet-tests.el ends here
