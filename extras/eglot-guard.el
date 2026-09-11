;;; eglot-guard.el --- shared "skip eglot until a binary exists" helper  -*- lexical-binding: t; -*-

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

(defun my-eglot-guard-until (modes ready-p)
  "Hold `my-eglot-ensure' back in MODES buffers until READY-P is satisfied.
MODES is a mode symbol, or a list of mode symbols -- any of them being the
current buffer's mode (per `derived-mode-p') blocks.  READY-P is a string,
checked via `executable-find', or a function of no arguments called fresh
each time and treated as ready when it returns non-nil.
Returns the advice name added (a symbol), or nil if `my-eglot-ensure' is not
yet defined -- nothing to advise in that case."
  (when (fboundp 'my-eglot-ensure)
    (let* ((modes (if (listp modes) modes (list modes)))
           (check (if (stringp ready-p) (lambda () (executable-find ready-p)) ready-p))
           (name (make-symbol (format "my-eglot-guard-until--%s" modes))))
      (advice-add 'my-eglot-ensure :before-while
                  (lambda () (or (not (apply #'derived-mode-p modes)) (funcall check)))
                  `((name . ,name)))
      name)))

(provide 'eglot-guard)
