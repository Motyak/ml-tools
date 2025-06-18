#!/bin/bash
set -o errexit

trap 'rm -rf "$TMPDIR"; jobs -p | xargs -r kill' EXIT

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
        >/dev/null tee "$TMPFILE"
        cat "$TMPFILE" > "$PIPE2"
        cat "$TMPFILE" > "$PIPE1"
    done

# stdin mode #
elif [ "$1" == "-" ]; then
    TMPDIR="$(mktemp -d)"
    TMPFILE="$(mktemp -p "$TMPDIR")"
    >/dev/null tee "$TMPFILE"
    monlang-parser/bin/main.elf\ -o - < "$TMPFILE"
    monlang-interpreter/bin/main.elf - < "$TMPFILE"

# filein mode #
else
    monlang-parser/bin/main.elf\ -o "$1"
    monlang-interpreter/bin/main.elf "$1"
fi


