;;; typescript.el --- JavaScript / TypeScript development extras  -*- lexical-binding: t; -*-

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
;;     wired below as `prettier-format-on-save-mode' via reformatter.el;
;;     `eglot-format-buffer' would call tsserver's own formatter instead,
;;     which isn't Prettier-aware. Both this and the ESLint check above
;;     prefer a project-local node_modules/.bin binary when one exists.
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

;;; Built-in
;; Prefer a project-local npm binary (node_modules/.bin) over a global one,
;; so per-project ESLint/Prettier versions win when they exist.
(defun my-typescript--npm-bin (name)
  "Return the project-local node_modules/.bin/NAME if it exists, else NAME."
  (if-let* ((root (locate-dominating-file default-directory "node_modules"))
            (bin (expand-file-name (concat "node_modules/.bin/" name) root))
            ((file-executable-p bin)))
      bin
    name))

;; No flymake/LSP wiring for ESLint here (typescript-language-server doesn't
;; run it) — just a `compile' wrapper with the usual next-error navigation.
(defun my-typescript-eslint-check ()
  "Run ESLint on the current file in a `compile' buffer."
  (interactive)
  (compile (format "%s %s" (my-typescript--npm-bin "eslint")
                    (shell-quote-argument buffer-file-name))))

;; JavaScript + JSX → js-ts-mode (the built-in js.el tree-sitter mode).
(use-package js
  :ensure nil
  :bind (:map js-ts-mode-map ("C-c C-l" . my-typescript-eslint-check))
  :hook (js-ts-mode . prettier-format-on-save-mode)
  :init
  ;; Register the grammar source (no URL prompt on install); remap the js majors
  ;; to js-ts-mode once the grammar exists.
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(javascript "https://github.com/tree-sitter/tree-sitter-javascript"))
    ;; auto-install the grammar on first load (needs git + a C compiler).
    (unless (treesit-language-available-p 'javascript)
      (with-demoted-errors "treesit: %S" (treesit-install-language-grammar 'javascript)))
    (when (treesit-language-available-p 'javascript)
      (dolist (m '(js-mode javascript-mode js-jsx-mode jsx-mode))
        (add-to-list 'major-mode-remap-alist (cons m 'js-ts-mode)))
      (add-to-list 'auto-mode-alist '("\\.jsx\\'" . js-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.m?js\\'" . js-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.cjs\\'" . js-ts-mode))))
  :custom
  (js-indent-level 2))

;; TypeScript → typescript-ts-mode, TSX → tsx-ts-mode. Emacs doesn't bind .ts /
;; .tsx by default, so wire them up (only when the grammar is built — eglot
;; still attaches even if a file opens in fundamental-mode).
(use-package typescript-ts-mode
  :ensure nil
  :init
  ;; Both grammars live in ONE repo, under typescript/src and tsx/src — encode
  ;; those subdirs so install needs no URL. Bind the ts-modes once built.
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(typescript "https://github.com/tree-sitter/tree-sitter-typescript"
                              nil "typescript/src"))
    (add-to-list 'treesit-language-source-alist
                 '(tsx "https://github.com/tree-sitter/tree-sitter-typescript"
                       nil "tsx/src"))
    ;; auto-install missing grammars on first load (needs git + a C compiler).
    (dolist (lang '(typescript tsx))
      (unless (treesit-language-available-p lang)
        (with-demoted-errors "treesit: %S" (treesit-install-language-grammar lang))))
    (when (treesit-language-available-p 'typescript)
      (add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.mts\\'" . typescript-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.cts\\'" . typescript-ts-mode)))
    (when (treesit-language-available-p 'tsx)
      (add-to-list 'major-mode-remap-alist '(tsx-mode . tsx-ts-mode))
      (add-to-list 'major-mode-remap-alist '(typescript-tsx-mode . tsx-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))))
  :bind (:map typescript-ts-mode-map ("C-c C-l" . my-typescript-eslint-check)
         :map tsx-ts-mode-map ("C-c C-l" . my-typescript-eslint-check))
  :hook ((typescript-ts-mode tsx-ts-mode) . prettier-format-on-save-mode)
  :custom
  (typescript-ts-mode-indent-offset 2))
;;; End Built-in

;;; NonGNU ELPA
;; Prettier, wired as format-on-save (see `my-typescript--npm-bin' above for
;; which binary it picks). Needs Prettier reachable, either project-local
;; (npm install -D prettier) or global (npm install -g prettier).
(use-package reformatter
  :ensure t
  :config
  (reformatter-define prettier-format
    :program (my-typescript--npm-bin "prettier")
    :args (list "--stdin-filepath" buffer-file-name)
    :lighter " Prettier"))
;;; End NonGNU ELPA

;;; GNU ELPA
;; DAP-based debugging that pairs with eglot (no lsp-mode needed). To debug:
;; M-x dape, choose a `js-debug-*' config (Node or Chrome; it uses the
;; vscode-js-debug adapter). Set breakpoints with `dape-breakpoint-toggle';
;; n / c step once a session stops.
(use-package dape
  :ensure t
  :commands (dape dape-breakpoint-toggle)
  :custom
  (dape-buffer-window-arrangement 'right)  ; debugger windows on the right
  (dape-inlay-hints t))                     ; show variable values inline when stopped
;;; End GNU ELPA

(provide 'typescript)
;;; typescript.el ends here
