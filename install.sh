#!/bin/bash
# set -o xtrace #debug
set -o errexit

./build.sh

ln -s "$(realpath monlang.sh)" ~/.local/bin/monlang
ln -s "$(realpath monlang-server/monlang_server.sh)" ~/.local/bin/monlang_server
ln -s "$(realpath monlang-server/open_monlang.sh)" ~/.local/bin/open_monlang
