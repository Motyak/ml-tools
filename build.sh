#!/bin/bash
# set -o xtrace #debug
set -o errexit
shopt -s expand_aliases

function emptydir (
    [ -d "$1" ] || return 2
    shopt -s nullglob
    local files=("$1"/*)
    [ ${#files[@]} -eq 0 ]
)

alias make='make -j16'

cd "$(dirname "$0")"

git submodule sync
emptydir monlang && git submodule update --init
git submodule foreach git checkout master
git submodule foreach git pull origin master --ff-only

make -C monlang -q main --no-print-directory || exit_code=$?
[ "$exit_code" == 1 ] && make -C monlang dist # should (re)build
[ "$exit_code" == 2 ] && exit 2 # error in makefile
make -C monlang-parser bin/main.elf CXX=g++
make -C monlang-interpreter bin/main.elf CXX=g++
