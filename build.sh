#!/bin/bash
# set -o xtrace #debug
shopt -s expand_aliases

function emptydir (
    local dir="$1"
    shopt -s failglob
    { : ${dir}/*; } 2>/dev/null
)

alias make='make -j16'

git submodule sync
emptydir monlang && git submodule update --init
git submodule foreach git checkout master
git submodule foreach git pull origin master --ff-only

(
    make -C monlang -q main; exit_code=$?
    [ $exit_code -eq 1 ] && make -C monlang dist # should (re)build
    [ $exit_code -eq 2 ] && exit 2 # error in makefile
    set -o errexit
    make -C monlang-parser bin/main.elf CXX=g++
    make -C monlang-interpreter bin/main.elf CXX=g++
)
