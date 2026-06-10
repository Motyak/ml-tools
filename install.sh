#!/bin/bash
# set -o xtrace #debug
set -o errexit

./build.sh

cd "$(dirname "$0")"

mkdir -p ~/.local/bin
set -o verbose
ln -fs "$(realpath monlang.sh)" ~/.local/bin/monlang
ln -fs "$(realpath monlang-server/monlang_server.sh)" ~/.local/bin/monlang_server
ln -fs "$(realpath monlang-server/open_monlang.sh)" ~/.local/bin/open_monlang
ln -fs "$(realpath mlp/mlp.sh)" ~/.local/bin/mlp
set +o verbose

echo -e "\nInstallation is DONE"
if ! [[ "$PATH" =~ "$HOME/.local/bin:" ]]; then
    echo "We have noticed \$HOME/.local/bin is not set in your current \$PATH,"
    echo -en "would you like us to add it for you ? (Y/n)\n> "
    read confirm
    [[ "$confirm" =~ n|N ]] && { echo "aborted"; exit 0; }
    echo $'\n''export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo "For changes to take effect in current terminal, "
    echo "please run command \`source ~/.bashrc\`"
fi
