#!/bin/bash
set -o errexit

function die {
    >&2 echo $@
    exit 1
}

[ "$1" != "" ] || die "Expected a file argument"
[ -f "$1" ] || die "Cannot find file \`$1\`"

monlang-parser/bin/main.elf\ -o $@
monlang-interpreter/bin/main.elf $@
