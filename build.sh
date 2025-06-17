#!/bin/bash
# set -o xtrace #debug
shopt -s expand_aliases

alias make='make -j16'

git submodule sync
git submodule update --init
git submodule update --remote

(
    set -o errexit
    make -C monlang dist
    make -C monlang-parser bin/main.elf
    make -C monlang-interpreter bin/main.elf
)
