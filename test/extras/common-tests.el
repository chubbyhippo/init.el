;;; common-tests.el --- invariants that apply to every extras/*.el  -*- lexical-binding: t; -*-

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

;; extras/*.el keep only their mode-line header and license block as
;; comments -- every explanatory "guide" paragraph that used to live in each
;; file (external tools to install, why a hook is guarded, which ELPA archive
;; a package comes from, etc.) has been moved into the matching
;; test/extras/<lang>-tests.el instead, so that knowledge documents the tests
;; that pin the behavior down rather than sitting next to code a linter would
;; otherwise flag as dead commentary. This file only holds the two
;; structural invariants that apply to ALL of them at once.

(let ((dir (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "helpers" dir)))

;;; ============================================== comments were stripped
(ert-deftest extras-test/given-every-extras-file-then-only-license-and-header-comments-remain ()
  "Every extras/*.el keeps only its mode-line header (line 1, with the
lexical-binding cookie) and its 16-line license block (Copyright/SPDX) as
comments -- 17 full-line comments total, and not a single `;' character
anywhere after the license block (no section banners, no inline notes, no
commented-out example code)."
  (dolist (name extras-test--files)
    (ert-info ((format "file: %s" name))
      (with-temp-buffer
        (insert-file-contents (extras-test-file name))
        (goto-char (point-min))
        (should (looking-at ";;; .* --- .*-\\*- lexical-binding: t; -\\*-"))
        (let ((comment-lines 0))
          (save-excursion
            (while (not (eobp))
              (when (looking-at "^;") (setq comment-lines (1+ comment-lines)))
              (forward-line 1)))
          (should (= comment-lines 17)))
        (should (re-search-forward "^;; Copyright (C) 2026 Chubby Hippo$" nil t))
        (goto-char (point-min))
        (should (re-search-forward "^;; SPDX-License-Identifier: GPL-3.0-or-later$" nil t))
        (forward-line 1)
        (should-not (string-match-p ";" (buffer-substring-no-properties (point) (point-max))))))))

(ert-deftest extras-test/given-every-extras-file-then-it-still-parses-as-valid-elisp ()
  "Stripping comments must not have mangled any form."
  (dolist (name extras-test--files)
    (ert-info ((format "file: %s" name))
      (should (extras-test--forms name)))))

(provide 'extras-common-tests)
;;; common-tests.el ends here
