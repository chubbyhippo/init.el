#!/bin/sh
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
  -l "$here/init-tests.el" \
  -f ert-run-tests-batch-and-exit
