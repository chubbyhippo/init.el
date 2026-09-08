;;; typescript-tests.el --- ERT suite for extras/typescript.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/typescript.el (moved here when that file's
;; comments were stripped, so the rationale below still documents the tests
;; that pin its behavior down):
;;
;; Optional JS/TS layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. One file covers both
;; languages: they share a language server, a debug adapter, and tooling, so
;; splitting them would only duplicate config. Handles .js / .jsx / .ts / .tsx.
;;
;; Most of the stack is built in: the tree-sitter major modes (js-ts-mode,
;; typescript-ts-mode, tsx-ts-mode) and eglot, which init.el already hooks onto
;; prog-mode. You supply the external tools:
;;   - TypeScript compiler & LSP server:
;;       npm install -g typescript typescript-language-server
;;     — eglot launches `typescript-language-server' automatically for
;;     .js / .jsx / .ts / .tsx once it's on PATH.
;;   - Direct TypeScript runtimes (optional, for running/debugging without build step):
;;       npm install -g tsx ts-node
;;     — needed if running `js-debug-tsx' or `js-debug-ts-node' via dape.
;;   - the vscode-js-debug adapter — unpacked into
;;     ~/.config/emacs/debug-adapters/js-debug/, where dape's js-debug configs
;;     run its src/dapDebugServer.js; dape errors out if that file is missing.
;;   - the tree-sitter grammars (javascript, typescript, tsx) — AUTO-INSTALLED
;;     on first load from the sources registered in :init (which encode the
;;     typescript/src and tsx/src subdirs; needs git + a C compiler on PATH);
;;     until they build, .js falls back to js-mode and .ts/.tsx aren't
;;     auto-detected.
;;   - ESLint (npm install -g eslint, or as a project devDependency) — this
;;     file only gives you `my-typescript-eslint-check' (C-c C-l / M-x), a
;;     `compile' wrapper with next-error navigation, NOT a flymake backend;
;;     typescript-language-server above only ever reports tsserver's own
;;     diagnostics, never ESLint's.
;;   - Prettier (npm install -g prettier, or as a project devDependency) —
;;     wired as `prettier-format-on-save-mode' via reformatter.el;
;;     `eglot-format-buffer' would call tsserver's own formatter instead,
;;     which isn't Prettier-aware.
;;
;; All four npm-backed tools above (typescript-language-server, ESLint,
;; Prettier, and the tsx/ts-node runtimes dape launches) go through
;; `my-typescript--npm-bin', which prefers a project-local
;; node_modules/.bin/<name> over the global one on PATH — so per-project
;; versions win whenever `npm install -D' put one there, with the global
;; install only as a fallback for projects that have none; see the two
;; npm-bin tests below.
;;
;; Summary of external CLI setup:
;;   npm install -g typescript typescript-language-server tsx ts-node eslint prettier
;;
;; Debugging, by config (M-x dape):
;;   - js-debug-node / -node-attach / -chrome — JavaScript, and -attach and
;;     -chrome also serve TypeScript; these need nothing beyond the adapter
;;   - js-debug-ts-node needs `ts-node' and js-debug-tsx needs `tsx' on PATH (`npm i -g tsx ts-node').
;;     To debug TypeScript without either, attach to `node --inspect' with
;;     js-debug-node-attach, or debug the compiled output with js-debug-node and a source map.
;;
;; ELPA-only: dape is on GNU ELPA, reformatter is on NonGNU ELPA; the major
;; modes and eglot are built in. (typescript-mode / tide / lsp-* /
;; flymake-eslint / apheleia are MELPA-only, so they're not used here.)
;;
;; Overriding eglot's own default (plain PATH lookup) via
;; `my-typescript--lsp-contact' makes a project-local
;; typescript-language-server win too, same as ESLint/Prettier.
;;
;; Both grammars for typescript/tsx live in ONE upstream repo, under
;; typescript/src and tsx/src — the :init block encodes those subdirs so
;; install needs no URL.
;;
;; js-debug-tsx / js-debug-ts-node hardcode "tsx" / "ts-node" as the
;; :runtimeExecutable, which vscode-js-debug then resolves off PATH — dape's
;; :config patches both to prefer node_modules/.bin, evaluated fresh at
;; launch (dape evaluates non-keyword list-valued config entries, see
;; dape--config-eval).

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ============================================================ typescript.el
(ert-deftest extras-test/given-typescript-then-npm-bin-prefers-a-project-local-binary ()
  (extras-test--eval-def "typescript.el" 'defun 'my-typescript--npm-bin)
  (let* ((root (make-temp-file "ts-project" t))
         (bindir (expand-file-name "node_modules/.bin/" root))
         (bin (expand-file-name "eslint" bindir)))
    (unwind-protect
        (progn
          (make-directory bindir t)
          (write-region "" nil bin)
          (cl-letf (((symbol-function 'file-executable-p)
                     (lambda (f) (equal f bin))))
            (should (equal (my-typescript--npm-bin "eslint" root) bin))
            (should (equal (my-typescript--npm-bin "nonexistent-tool" root) "nonexistent-tool"))))
      (delete-directory root t))))

(ert-deftest extras-test/given-typescript-then-npm-bin-falls-back-to-the-bare-name ()
  (extras-test--eval-def "typescript.el" 'defun 'my-typescript--npm-bin)
  (let ((root (make-temp-file "ts-no-node-modules" t)))
    (unwind-protect
        (should (equal (my-typescript--npm-bin "prettier" root) "prettier"))
      (delete-directory root t))))

(ert-deftest extras-test/given-typescript-then-lsp-contact-runs-the-server-over-stdio ()
  (extras-test--eval-def "typescript.el" 'defun 'my-typescript--npm-bin)
  (extras-test--eval-def "typescript.el" 'defun 'my-typescript--lsp-contact)
  (should (equal (my-typescript--lsp-contact nil nil)
                 '("typescript-language-server" "--stdio"))))

(ert-deftest extras-test/given-typescript-then-eglot-learns-the-project-aware-contact-fn ()
  (extras-test--eval-def "typescript.el" 'defun 'my-typescript--npm-bin)
  (extras-test--eval-def "typescript.el" 'defun 'my-typescript--lsp-contact)
  (let ((eglot-server-programs nil))
    (extras-test--eval-with-eval-after-load "typescript.el" 'eglot)
    (should (equal (cdr (assoc '((js-mode :language-id "javascript")
                                (js-ts-mode :language-id "javascript")
                                (tsx-ts-mode :language-id "typescriptreact")
                                (typescript-ts-mode :language-id "typescript")
                                (typescript-mode :language-id "typescript"))
                               eglot-server-programs))
                   'my-typescript--lsp-contact))))

(ert-deftest extras-test/given-typescript-then-eslint-check-shells-out-through-compile ()
  (extras-test--eval-def "typescript.el" 'defun 'my-typescript--npm-bin)
  (extras-test--eval-def "typescript.el" 'defun 'my-typescript-eslint-check)
  (let (compile-command-used)
    (cl-letf (((symbol-function 'compile) (lambda (cmd) (setq compile-command-used cmd))))
      (with-temp-buffer
        (setq buffer-file-name (expand-file-name "app.ts" temporary-file-directory))
        (my-typescript-eslint-check)))
    (should (string-match-p "\\`eslint " compile-command-used))
    (should (string-match-p "app\\.ts" compile-command-used))))

(ert-deftest extras-test/given-typescript-then-js-and-ts-map-to-their-tree-sitter-modes ()
  (should (extras-test--declares "typescript.el" '("\\.m?js\\'" . js-ts-mode)))
  (should (extras-test--declares "typescript.el" '("\\.ts\\'" . typescript-ts-mode)))
  (should (extras-test--declares "typescript.el" '("\\.tsx\\'" . tsx-ts-mode))))

(ert-deftest extras-test/given-typescript-then-prettier-runs-on-save-for-js-ts-and-tsx ()
  (should (member '(js-ts-mode . prettier-format-on-save-mode)
                  (extras-test--use-package-section "typescript.el" 'js :hook)))
  (should (member '((typescript-ts-mode tsx-ts-mode) . prettier-format-on-save-mode)
                  (extras-test--use-package-section "typescript.el" 'typescript-ts-mode :hook))))

(ert-deftest extras-test/given-typescript-then-it-provides-typescript ()
  (should (extras-test--declares "typescript.el" '(provide 'typescript))))

(provide 'typescript-tests)
;;; typescript-tests.el ends here
