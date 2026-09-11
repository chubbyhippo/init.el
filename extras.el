;;; extras.el --- optional language layers (disabled by default)  -*- lexical-binding: t; -*-

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

;;; Commentary:

;; init.el's own (load "extras.el" ...) call is commented out, so this file
;; is not reached at all right now, regardless of what is uncommented below.
;; Every per-language loader here is live code; re-enable init.el's call to
;; make them take effect, then reload (C-c e M / my-reload-init-file).

;;; Code:

(load (expand-file-name "extras/clojure.el"    user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/cobol.el"      user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/cpp.el"        user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/dotnet.el"     user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/elixir.el"     user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/erlang.el"     user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/go.el"         user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/haskell.el"    user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/html.el"       user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/java.el"       user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/json.el"       user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/kotlin.el"     user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/markdown.el"   user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/perl.el"       user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/php.el"        user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/python.el"     user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/ruby.el"       user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/rust.el"       user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/scheme.el"     user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/sql.el"        user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/typescript.el" user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/xml.el"        user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/yaml.el"       user-emacs-directory) :noerror :nomessage)
(load (expand-file-name "extras/zig.el"        user-emacs-directory) :noerror :nomessage)

(provide 'extras)
;;; extras.el ends here
