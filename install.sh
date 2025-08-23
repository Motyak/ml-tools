#!/bin/bash
# set -o xtrace #debug
set -o errexit

./build.sh

set -o verbose
ln -fs "$(realpath monlang.sh)" ~/.local/bin/monlang
ln -fs "$(realpath monlang-server/monlang_server.sh)" ~/.local/bin/monlang_server
ln -fs "$(realpath monlang-server/open_monlang.sh)" ~/.local/bin/open_monlang
ln -fs "$(realpath mlp/mlp.sh)" ~/.local/bin/mlp
