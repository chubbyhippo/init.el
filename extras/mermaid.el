;;; mermaid.el --- Mermaid diagram rendering extras  -*- lexical-binding: t; -*-

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

(defun my-mermaid--npm-bin (name &optional dir)
  "Return the project-local node_modules/.bin/NAME under DIR, else NAME."
  (if-let* ((root (locate-dominating-file (or dir default-directory) "node_modules"))
            (bin (expand-file-name (concat "node_modules/.bin/" name) root))
            ((file-executable-p bin)))
      bin
    name))

(defun my-mermaid--block-bounds (&optional pos)
  "Bounds (BEG . END) of the ```mermaid fenced code block content enclosing
POS (or point), excluding the fence lines themselves -- nil if POS is not
inside one."
  (let ((pos (or pos (point))))
    (save-excursion
      (save-match-data
        (goto-char pos)
        (end-of-line)
        (when (re-search-backward "^```+[ \t]*mermaid[ \t]*$" nil t)
          (forward-line 1)
          (let ((beg (point)))
            (when (re-search-forward "^```+[ \t]*$" nil t)
              (let ((end (match-beginning 0))
                    (fence-end (match-end 0)))
                (when (and (<= beg pos) (<= pos fence-end))
                  (cons beg end))))))))))

(defun my-mermaid--source-text ()
  "Text of the diagram to render: the whole buffer for a standalone
.mmd/.mermaid file, else the ```mermaid fenced block at point."
  (cond
   ((and buffer-file-name (string-match-p "\\.mmd\\'\\|\\.mermaid\\'" buffer-file-name))
    (buffer-substring-no-properties (point-min) (point-max)))
   ((my-mermaid--block-bounds)
    (let ((bounds (my-mermaid--block-bounds)))
      (buffer-substring-no-properties (car bounds) (cdr bounds))))
   (t (user-error "No Mermaid diagram here: not a .mmd/.mermaid file, and point is not inside a ```mermaid block"))))

(defun my-mermaid-render ()
  "Render the Mermaid diagram at point (or the whole buffer, for a
standalone .mmd/.mermaid file) to SVG via mermaid-cli's `mmdc', and open
the result.  Requires `npm install -g @mermaid-js/mermaid-cli'."
  (interactive)
  (let ((mmdc (my-mermaid--npm-bin "mmdc")))
    (unless (or (file-name-absolute-p mmdc) (executable-find mmdc))
      (user-error "mmdc not found -- install with `npm install -g @mermaid-js/mermaid-cli'"))
    (let* ((source (my-mermaid--source-text))
           (in-file (make-temp-file "mermaid" nil ".mmd" source))
           (out-file (concat (file-name-sans-extension in-file) ".svg")))
      (unwind-protect
          (if (zerop (call-process mmdc nil "*mermaid-render*" nil
                                    "-i" in-file "-o" out-file))
              (find-file-other-window out-file)
            (pop-to-buffer "*mermaid-render*")
            (user-error "mmdc failed to render the diagram"))
        (delete-file in-file)))))

(with-eval-after-load 'markdown-mode
  (define-key markdown-mode-command-map "r" #'my-mermaid-render))

(provide 'mermaid)
