#!/bin/bash
set -e

_TMPL=$(dirname "$0")/.gitignore-tmpl

# Ban '/.idea/' - and potentially some others - from git.
#
# NOTE: This author thinks such exclusions do not make sense in a project specific '.gitignore' (where they often are).
#     It is not necessary for a project to use a certain IDE, for example.
#
cp $(_TMPL) ~/.gitignore

git config --global core.excludesfile ~/.gitignore
