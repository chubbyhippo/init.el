#!/bin/sh
# Copyright (C) 2026 Chubby Hippo
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Run init.el's ERT suite headless.
#
#   ./test/run.sh
#
# Reuses the packages installed under ~/.config/emacs/elpa (so meow loads
# offline); override the location with EMACS_ELPA=/path/to/elpa, or the Emacs
# binary with EMACS=/path/to/emacs.  If meow is missing there, the suite
# installs it from NonGNU ELPA on first run.
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
: "${EMACS:=emacs}"
elpa="${EMACS_ELPA:-$HOME/.config/emacs/elpa}"

exec "$EMACS" -Q --batch \
  --eval "(setq package-user-dir \"$elpa\")" \
  -l "$here/early-init-tests.el" \
  -l "$here/init-tests.el" \
  -l "$here/extras/common-tests.el" \
  -l "$here/extras/clojure-tests.el" \
  -l "$here/extras/cobol-tests.el" \
  -l "$here/extras/cpp-tests.el" \
  -l "$here/extras/elixir-tests.el" \
  -l "$here/extras/erlang-tests.el" \
  -l "$here/extras/go-tests.el" \
  -l "$here/extras/haskell-tests.el" \
  -l "$here/extras/html-tests.el" \
  -l "$here/extras/java-tests.el" \
  -l "$here/extras/json-tests.el" \
  -l "$here/extras/markdown-tests.el" \
  -l "$here/extras/perl-tests.el" \
  -l "$here/extras/php-tests.el" \
  -l "$here/extras/python-tests.el" \
  -l "$here/extras/ruby-tests.el" \
  -l "$here/extras/rust-tests.el" \
  -l "$here/extras/scheme-tests.el" \
  -l "$here/extras/typescript-tests.el" \
  -l "$here/extras/yaml-tests.el" \
  -l "$here/extras/zig-tests.el" \
  -f ert-run-tests-batch-and-exit
