;;; erlang.el --- Erlang development extras  -*- lexical-binding: t; -*-

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

(defun my-erlang--otp-emacs-dir ()
  "Return OTP's bundled emacs/ directory (home of erlang.el), or nil.
Ask `erl' for the `tools' application lib dir and append emacs/."
  (when (executable-find "erl")
    (let ((dir (ignore-errors
                 (string-trim
                  (shell-command-to-string
                   "erl -noshell -eval 'io:format(\"~s\", [filename:join(code:lib_dir(tools), \"emacs\")])' -s init stop")))))
      (and (stringp dir) (file-directory-p dir) dir))))

(unless (require 'erlang nil t)
  (when-let* ((dir (my-erlang--otp-emacs-dir)))
    (add-to-list 'load-path dir)
    (require 'erlang nil t)))

(when (featurep 'erlang)
  (setq erlang-indent-level 4)
  (dolist (entry '(("\\.erl\\'"              . erlang-mode)
                   ("\\.hrl\\'"              . erlang-mode)
                   ("\\.app\\(\\.src\\)?\\'" . erlang-mode)
                   ("/rebar\\.config\\'"     . erlang-mode)))
    (add-to-list 'auto-mode-alist entry)))
