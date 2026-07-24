;;; -*- lexical-binding: t; -*-

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

(progn
  (require 'url)
  (let* ((url-show-status nil)        ; silence url.el's "Contacting host: ..." progress line
         (base "https://raw.githubusercontent.com/chubbyhippo/init.el/refs/heads/main/")
         (dir  (expand-file-name "~/.config/emacs/")))
    (dolist (file '("early-init.el"
                    "init.el"
                    "extras/clojure.el"
                    "extras/cpp.el"
                    "extras/elixir.el"
                    "extras/erlang.el"
                    "extras/go.el"
                    "extras/java.el"
                    "extras/python.el"
                    "extras/rust.el"
                    "extras/scheme.el"
                    "extras/typescript.el"
                    "extras/zig.el"))
      (let ((dest (expand-file-name file dir)))
        (make-directory (file-name-directory dest) t)  ; create dir / extras/ as needed
        (let ((inhibit-message t))
          (url-copy-file (concat base file) dest t))
        (message "Installed %s" dest)))))
