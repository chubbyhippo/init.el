;;; mermaid-tests.el --- ERT suite for extras/mermaid.el  -*- lexical-binding: t; -*-

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

;; Guide retained from extras/mermaid.el (moved here when that file's
;; comments were stripped, so the rationale below still documents the tests
;; that pin its behavior down):
;;
;; Optional Mermaid diagram layer for init.el. Disabled by default --
;; uncomment the matching loader in extras.el to enable it. Unlike every
;; other extras/*.el, this one adds no major mode and no LSP -- Mermaid is
;; a diagram DSL you render, not a language you get completion/xref for.
;;
;; NO MAJOR MODE, and none is added. `mermaid-mode' (abrochard/mermaid-mode)
;; is the only Emacs mode for standalone .mmd/.mermaid files, and it is
;; MELPA-only (checked both official archives directly -- absent from
;; both), so this config's "never MELPA" rule rules it out. Standalone
;; .mmd/.mermaid files fall back to plain `fundamental-mode'; diagrams
;; embedded in a ```mermaid fenced block inside a markdown-mode buffer
;; (extras/markdown.el) get markdown-mode's own generic code-block face,
;; not Mermaid-specific syntax highlighting -- `markdown-fontify-code-
;; blocks-natively' would only add real highlighting if `mermaid-mode'
;; itself were installed, which this layer deliberately avoids.
;;
;; NO tree-sitter path either: monaqa/tree-sitter-mermaid and similar
;; grammars exist upstream, but no consuming Emacs major mode ships in
;; core or lives on GNU/NonGNU ELPA.
;;
;; What this layer DOES add: `my-mermaid-render' (M-x, and C-c C-c r inside
;; markdown-mode's own command map), which renders the diagram to SVG via
;; mermaid-cli's `mmdc' and opens it. The diagram source is either the
;; whole buffer (a standalone .mmd/.mermaid file) or the ```mermaid fenced
;; block enclosing point (detected with a self-contained regexp scan for
;; the opening/closing fence lines, not markdown-mode's own internal
;; `markdown-code-block-at-pos' -- keeping this layer usable, and testable,
;; without markdown-mode installed at all). Point must be BETWEEN the
;; fences (not merely near them) for a block to count.
;;
;; You supply the external tool: mermaid-cli
;; (github.com/mermaid-js/mermaid-cli), installed via
;; `npm install -g @mermaid-js/mermaid-cli', which puts `mmdc' on PATH.
;; Like typescript.el, `my-mermaid--npm-bin' prefers a project-local
;; node_modules/.bin/mmdc over the global one. `my-mermaid-render' checks
;; for it up front and raises a clear `user-error' with the install
;; command if it is missing, rather than a bare mmdc/call-process
;; failure -- and cleans up its temporary .mmd input file either way,
;; success or failure, leaving only the rendered .svg behind.
;;
;; The C-c C-c r binding is added directly to `markdown-mode-command-map'
;; (the prefix markdown-mode itself puts on C-c C-c) via
;; `with-eval-after-load' rather than a hard `require' -- so it activates
;; whenever markdown-mode happens to load, regardless of whether that is
;; through extras/markdown.el or the user's own config, and this layer
;; never forces markdown-mode to load on its own. `r' was free in that
;; map (m/p/e/v/o/l/w/c/u/n/]/^/| /t are all already bound upstream).
;;
;; No dape config: Mermaid is a diagram DSL, not executable code.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; =============================================================== mermaid.el
(ert-deftest extras-test/given-mermaid-then-npm-bin-prefers-a-project-local-binary ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--npm-bin)
  (let* ((root (make-temp-file "mmd-project" t))
         (bindir (expand-file-name "node_modules/.bin/" root))
         (bin (expand-file-name "mmdc" bindir)))
    (unwind-protect
        (progn
          (make-directory bindir t)
          (write-region "" nil bin)
          (cl-letf (((symbol-function 'file-executable-p)
                     (lambda (f) (equal f bin))))
            (should (equal (my-mermaid--npm-bin "mmdc" root) bin))))
      (delete-directory root t))))

(ert-deftest extras-test/given-mermaid-then-npm-bin-falls-back-to-the-bare-name ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--npm-bin)
  (let ((root (make-temp-file "mmd-no-node-modules" t)))
    (unwind-protect
        (should (equal (my-mermaid--npm-bin "mmdc" root) "mmdc"))
      (delete-directory root t))))

(ert-deftest extras-test/given-mermaid-then-block-bounds-finds-the-enclosing-fence ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--block-bounds)
  (with-temp-buffer
    (insert "# Title\n\nSome text\n\n```mermaid\ngraph TD\n  A --> B\n```\n\nMore text\n")
    (goto-char (point-min))
    (search-forward "A --> B")
    (let ((bounds (my-mermaid--block-bounds)))
      (should bounds)
      (should (equal (buffer-substring-no-properties (car bounds) (cdr bounds))
                     "graph TD\n  A --> B\n")))))

(ert-deftest extras-test/given-mermaid-then-block-bounds-is-nil-outside-any-fence ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--block-bounds)
  (with-temp-buffer
    (insert "# Title\n\nSome text\n\n```mermaid\ngraph TD\n  A --> B\n```\n\nMore text\n")
    (goto-char (point-min))
    (search-forward "Some text")
    (should-not (my-mermaid--block-bounds))
    (goto-char (point-min))
    (search-forward "More text")
    (should-not (my-mermaid--block-bounds))))

(ert-deftest extras-test/given-mermaid-then-block-bounds-ignores-non-mermaid-fences ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--block-bounds)
  (with-temp-buffer
    (insert "```js\nconsole.log(1)\n```\n")
    (goto-char (point-min))
    (search-forward "console")
    (should-not (my-mermaid--block-bounds))))

(ert-deftest extras-test/given-mermaid-then-source-text-uses-the-whole-buffer-for-a-standalone-file ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--block-bounds)
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--source-text)
  (with-temp-buffer
    (setq buffer-file-name (expand-file-name "diagram.mmd" temporary-file-directory))
    (insert "graph TD\n  A --> B\n")
    (should (equal (my-mermaid--source-text) "graph TD\n  A --> B\n"))))

(ert-deftest extras-test/given-mermaid-then-source-text-uses-the-fenced-block-at-point ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--block-bounds)
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--source-text)
  (with-temp-buffer
    (insert "```mermaid\ngraph TD\n  A --> B\n```\n")
    (goto-char (point-min))
    (search-forward "A --> B")
    (should (equal (my-mermaid--source-text) "graph TD\n  A --> B\n"))))

(ert-deftest extras-test/given-mermaid-then-source-text-errors-with-neither ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--block-bounds)
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--source-text)
  (with-temp-buffer
    (insert "just some prose, no diagram here\n")
    (goto-char (point-min))
    (should-error (my-mermaid--source-text) :type 'user-error)))

(ert-deftest extras-test/given-mermaid-then-render-errors-cleanly-without-mmdc ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--npm-bin)
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--block-bounds)
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--source-text)
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid-render)
  (with-temp-buffer
    (insert "```mermaid\ngraph TD\n  A --> B\n```\n")
    (goto-char (point-min))
    (search-forward "A --> B")
    (cl-letf (((symbol-function 'executable-find) (lambda (_) nil)))
      (should-error (my-mermaid-render) :type 'user-error))))

(ert-deftest extras-test/given-mermaid-then-render-writes-the-source-and-opens-the-svg ()
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--npm-bin)
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--block-bounds)
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid--source-text)
  (extras-test--eval-def "mermaid.el" 'defun 'my-mermaid-render)
  (with-temp-buffer
    (insert "```mermaid\ngraph TD\n  A --> B\n```\n")
    (goto-char (point-min))
    (search-forward "A --> B")
    (let (in-file-content opened-file)
      (cl-letf (((symbol-function 'executable-find) (lambda (_) "/usr/bin/mmdc"))
                ((symbol-function 'call-process)
                 (lambda (_prog _infile _buf _display &rest args)
                   (setq in-file-content
                         (with-temp-buffer
                           (insert-file-contents (nth 1 args))
                           (buffer-string)))
                   0))
                ((symbol-function 'find-file-other-window)
                 (lambda (f) (setq opened-file f))))
        (my-mermaid-render))
      (should (equal in-file-content "graph TD\n  A --> B\n"))
      (should (string-suffix-p ".svg" opened-file)))))

(ert-deftest extras-test/given-mermaid-then-the-render-command-joins-markdown-c-c-c-map ()
  "The C-c C-c r binding activates only once markdown-mode itself loads --
guarded by with-eval-after-load, not a hard require of markdown-mode."
  (should (extras-test--declares
           "mermaid.el"
           '(define-key markdown-mode-command-map "r" #'my-mermaid-render))))

(ert-deftest extras-test/given-mermaid-then-it-provides-mermaid ()
  (should (extras-test--declares "mermaid.el" '(provide 'mermaid))))

(provide 'mermaid-tests)
;;; mermaid-tests.el ends here

