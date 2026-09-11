;;; xml-tests.el --- ERT suite for extras/xml.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/xml.el (moved here when that file's comments
;; were stripped, so the rationale below still documents the tests that pin
;; its behavior down):
;;
;; Optional XML layer for init.el. Disabled by default -- uncomment the
;; matching loader in extras.el to enable it. `nxml-mode' is built in and
;; already covers .xml / .xsl / .xsd / .svg / .dbk via its own default
;; auto-mode-alist entries (through the `xml-mode' alias `fset' onto it),
;; so unlike most other extras/*.el this layer adds no :mode of its own --
;; only LSP wiring, same shape as sql.el.
;;
;; There is NO tree-sitter path. tree-sitter-grammars/tree-sitter-xml
;; exists upstream, but no consuming Emacs major mode ships in core or
;; lives on GNU/NonGNU ELPA (only MELPA-only forks), so this config's
;; ELPA-only rule leaves nxml-mode's own regexp-based parsing in place.
;;
;; WHY THE eglot HOOK IS ADDED DIRECTLY. nxml-mode derives from
;; `text-mode', NOT `prog-mode' -- confirmed straight from nxml-mode.el's
;; own `define-derived-mode' -- so init.el's global prog-mode hook never
;; reaches XML buffers, the same gap extras/html.el patches for html-mode,
;; extras/yaml.el for yaml-ts-mode, and extras/markdown.el for
;; markdown-mode. This layer hooks `my-eglot-ensure' onto `nxml-mode'
;; directly; `xml-mode' buffers get it too, since `xml-mode' is `fset' to
;; `nxml-mode' itself, not a derived mode with its own hook variable.
;;
;; WHY THE eglot HOOK IS ALSO GUARDED. Unlike html.el/yaml.el/markdown.el
;; -- where eglot's own table already maps the mode to a known server --
;; eglot ships NO built-in XML entry at all, so this layer registers one
;; itself (same situation as cobol.el, sql.el, kotlin.el). Without a
;; guard, hooking `my-eglot-ensure' onto `nxml-mode' would mean "Searching
;; for program: ... lemminx" in *Warnings* on every .xml file until the
;; server is actually installed; the guard is the shared
;; `my-eglot-guard-until' helper from extras/eglot-guard.el (pulled in via
;; `require' with an explicit file path), behaviorally tested once in
;; eglot-guard-tests.el -- same helper as cobol.el/sql.el/kotlin.el/
;; dotnet.el/java.el.
;;
;; You supply the external tool: lemminx (github.com/eclipse-lemminx/lemminx),
;; the de-facto standard XML language server (Java, built on Eclipse
;; LSP4J + Xerces; the same server vscode-xml, coc-xml and lsp-mode's
;; lsp-xml.el all drive). It ships as an "uber" jar with no bundled
;; launcher of its own -- `java -jar org.eclipse.lemminx-uber.jar`, or a
;; prebuilt native binary from redhat-developer/vscode-xml's releases
;; (platform/arch-suffixed, e.g. lemminx-linux-x86_64, not plain
;; `lemminx`). Package managers that DO produce a plain `lemminx` wrapper
;; on PATH -- e.g. `nix-shell -p lemminx` -- are the simplest path to the
;; bare invocation this layer expects; otherwise rename/symlink whichever
;; binary you build or download to `lemminx` yourself.
;;
;; NO debug adapter, and none is wanted: XML is data, not executable code.
;;
;; No `(provide 'xml)' collision risk was checked the way json.el/yaml.el
;; worry about it -- `xml' the built-in library (lisp/xml.el, XML parsing
;; functions like `xml-parse-region') already `(provide 'xml)`s itself, so
;; this layer providing the same symbol again is harmless (Emacs allows a
;; feature to be provided more than once) but adds no protection either;
;; it is `(provide 'xml)`d here purely for consistency with every other
;; extras/*.el that has no name-clash concern.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ==================================================================== xml.el
(ert-deftest extras-test/given-xml-then-it-gets-the-missing-eglot-hook ()
  "nxml-mode derives from text-mode, so init.el's prog-mode hook never fires
for it; this hooks my-eglot-ensure directly instead, same gap html.el/
yaml.el/markdown.el each patch for their own text-mode-derived major mode."
  (should (member '(nxml-mode . my-eglot-ensure)
                  (extras-test--use-package-section "xml.el" 'nxml-mode :hook))))

(ert-deftest extras-test/given-xml-then-eglot-learns-lemminx ()
  (let ((eglot-server-programs nil))
    (extras-test--eval-with-eval-after-load "xml.el" 'eglot)
    (should (equal (cdr (assoc 'nxml-mode eglot-server-programs)) '("lemminx")))))

(ert-deftest extras-test/given-xml-then-it-requires-the-shared-eglot-guard ()
  (should (extras-test--declares
           "xml.el"
           '(require 'eglot-guard (expand-file-name "extras/eglot-guard" user-emacs-directory)))))

(ert-deftest extras-test/given-xml-then-eglot-is-skipped-until-lemminx-exists ()
  "xml.el delegates the skip-until-binary advice to the shared
my-eglot-guard-until helper (behaviorally tested on its own in
eglot-guard-tests.el) rather than hand-rolling it."
  (should (extras-test--declares
           "xml.el" '(my-eglot-guard-until 'nxml-mode "lemminx"))))

(ert-deftest extras-test/given-xml-then-it-provides-xml ()
  (should (extras-test--declares "xml.el" '(provide 'xml))))

(provide 'xml-tests)
;;; xml-tests.el ends here
