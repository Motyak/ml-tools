#!/bin/bash
set -o errexit

monlang-parser/bin/main.elf\ -o $@
monlang-interpreter/bin/main.elf $@
