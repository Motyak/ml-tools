#!/bin/bash
set -o errexit

trap 'rm -rf "$TMPDIR"; jobs -p | xargs -r kill' EXIT

function replace_shebang {
    awk 'NR == 1 && /^#!/ {printf "\x27"; for (i = 1; i <= length - 1; ++i) printf "1"; printf "\n"; next} {print}'
}

# REPL mode #
if [ "$1" == "" ]; then
    TMPDIR="$(mktemp -d)"
    TMPFILE="$(mktemp -p "$TMPDIR")"
    PIPE1="$(mktemp -u -p "$TMPDIR")"
    PIPE2="$(mktemp -u -p "$TMPDIR")"
    mkfifo "$PIPE1" "$PIPE2"
    monlang-parser/bin/main.elf\ -o < "$PIPE1" &
    monlang-interpreter/bin/main.elf < "$PIPE2" &
    while true; do
        tee "$TMPFILE" >/dev/null
        cat "$TMPFILE" > "$PIPE2"
        cat "$TMPFILE" > "$PIPE1"
    done

# stdin mode #
elif [ "$1" == "-" ]; then
    TMPDIR="$(mktemp -d)"
    TMPFILE="$(mktemp -p "$TMPDIR")"
    replace_shebang | tee "$TMPFILE" >/dev/null
    monlang-parser/bin/main.elf\ -o - < "$TMPFILE"
    monlang-interpreter/bin/main.elf - < "$TMPFILE"

# filein mode #
else
    TMPDIR="$(mktemp -d)"
    TMPFILE="$(mktemp -p "$TMPDIR")"
    replace_shebang < "$1" | tee "$TMPFILE" >/dev/null
    STDIN_SRCNAME="$1" monlang-parser/bin/main.elf\ -o - < "$TMPFILE"
    STDIN_SRCNAME="$1" monlang-interpreter/bin/main.elf - < "$TMPFILE"

fi
