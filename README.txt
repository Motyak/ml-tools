#!/bin/bash
set -o errexit
shopt -s expand_aliases

alias make='make -j16'

git clone --recurse-submodules https://github.com/Motyak/ml-tools.git

cd ml-tools

make -C monlang dist
make -C monlang-parser bin/main.elf
make -C monlang-interpreter bin/main.elf


