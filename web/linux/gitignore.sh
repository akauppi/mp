#!/bin/bash
set -e

# Ban '/.idea/' - and potentially some others - from git.
#
# NOTE: This author thinks such exclusions do not make sense in a project specific '.gitignore' (where they often are).
#     It is not necessary for a project to use a certain IDE, for example.
#
cat > ~/.gitignore << EOF
# IntelliJ
.idea/
EOF

echo >> ~/.bashrc 'git config --global core.excludesfile ~/.gitignore'
