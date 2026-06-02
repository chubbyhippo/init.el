#!/bin/sh

mkdir -p "$HOME"/.config/emacs/

curl https://raw.githubusercontent.com/chubbyhippo/init.el/refs/heads/main/early-init.el -o "$HOME"/.config/emacs/early-init.el
curl https://raw.githubusercontent.com/chubbyhippo/init.el/refs/heads/main/init.el -o "$HOME"/.config/emacs/init.el
