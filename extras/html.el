;;; html.el --- HTML / CSS development extras  -*- lexical-binding: t; -*-

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

;; Optional HTML/CSS layer for init.el. Disabled by default — uncomment the
;; matching loader at the bottom of init.el to enable it. One file covers both:
;; they share the same npm package for their language servers and are edited
;; together. Handles .html / .htm and .css (.scss keeps the built-in scss-mode).
;;
;; Every major mode here is ALREADY built in — mhtml-mode, html-mode, css-mode,
;; css-ts-mode, html-ts-mode all ship with Emacs 30 — so this layer is thin. It
;; exists for one reason that is easy to miss:
;;
;;   THE HTML MODES DERIVE FROM text-mode, NOT prog-mode.
;;   init.el hooks eglot onto prog-mode, so CSS buffers get a language server
;;   automatically and HTML buffers get NOTHING. This file adds the missing
;;   hook on html-mode, which mhtml-mode and html-ts-mode inherit.
;;
;; You supply the external tools:
;;   - vscode-html-language-server and vscode-css-language-server, both from
;;     `npm i -g vscode-langservers-extracted' — eglot already knows them: its
;;     built-in table maps html-mode and (css-mode css-ts-mode) to them
;;   - the css tree-sitter grammar — AUTO-INSTALLED on first load (needs git +
;;     a C compiler on PATH); until it builds, .css stays in the classic
;;     css-mode, which eglot drives just as well
;;
;; NO debug adapter, and none is wanted: HTML and CSS are not executed. Browser
;; debugging lives in extras/typescript.el, whose dape `js-debug-chrome' config
;; drives Chrome for the page's JavaScript.
;;
;; .html deliberately stays in mhtml-mode rather than html-ts-mode: only
;; mhtml-mode wires up the embedded <script>/<style> submodes, so a tree-sitter
;; remap would LOSE JS and CSS editing inside a page. The html grammar source is
;; registered anyway, so `M-x treesit-install-language-grammar html' needs no
;; URL if you ever want the plain tree-sitter mode. (Emacs 31's mhtml-ts-mode is
;; the one that finally combines both; revisit this when it lands.)
;;
;; ELPA-only: nothing is required from ELPA at all. emmet-mode, impatient-mode
;; and skewer-mode are MELPA-only, so they are not used here. web-mode IS on
;; NonGNU ELPA but is unneeded now that mhtml-mode handles the submodes.

;;; Built-in
(use-package css-mode
  :ensure nil
  :init
  ;; Register the grammar sources (no URL prompt on install); upgrade css-mode
  ;; to its tree-sitter twin once the grammar exists.  Only css is installed —
  ;; html-ts-mode is deliberately unused (see the header), so its grammar would
  ;; be dead weight.
  (when (and (require 'treesit nil t) (treesit-available-p))
    (add-to-list 'treesit-language-source-alist
                 '(css "https://github.com/tree-sitter/tree-sitter-css"))
    (add-to-list 'treesit-language-source-alist
                 '(html "https://github.com/tree-sitter/tree-sitter-html"))
    (unless (treesit-language-available-p 'css)
      (with-demoted-errors "treesit: %S" (treesit-install-language-grammar 'css)))
    (when (treesit-language-available-p 'css)
      (add-to-list 'major-mode-remap-alist '(css-mode . css-ts-mode))))
  :custom
  (css-indent-offset 2))

(use-package sgml-mode
  :ensure nil
  ;; The whole point of this file: html-mode descends from text-mode, so
  ;; init.el's prog-mode eglot hook never fires for it.  mhtml-mode and
  ;; html-ts-mode both derive from html-mode, so this one hook covers all three.
  ;; `eglot-ensure' directly rather than init.el's `my-eglot-ensure' — that
  ;; wrapper only exists to skip lisp modes, which HTML can never be.
  :hook (html-mode . eglot-ensure)
  :custom
  (sgml-basic-offset 2))
;;; End Built-in

;; Also on GNU/NonGNU ELPA if you want them — uncomment to enable:
;; (use-package rainbow-mode   ; paint #rrggbb / named colours in the buffer
;;   :ensure t                 ; GNU ELPA
;;   :hook (css-base-mode . rainbow-mode))
;; (use-package web-mode :ensure t) ; NonGNU ELPA; templating engines (jinja, erb, …)

;; No `(provide 'html)' — `html' is as generic a feature name as `go', and this
;; file is loaded by path from init.el, so a provide would only invite a clash.
;;; html.el ends here
