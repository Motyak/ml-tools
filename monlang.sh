#!/bin/bash

# NOTE: supporting the REPL mode for parser and interpreter simultaneously
#       has required a couple of hacks, but I think it is worth it.

[ "${BASH_SOURCE[0]}" == "$0" ] || {
    >&2 echo "script must be executed, not sourced"
    return 1
}

set -o errexit

trap 'rm -rf "$tmpdir"; jobs -p | xargs -r kill -9' EXIT

function replace_shebang {
    awk 'NR == 1 && /^#!/ {printf "\x27"; for (i = 1; i <= length - 1; ++i) printf "1"; printf "\n"; next} {print}'
}

[[ "$1" =~ ^(--)?$ ]] || FILEPATH="$(realpath "$1")"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# REPL mode #
if [[ "$1" =~ ^(--)?$ ]]; then
    tmpdir="$(mktemp -d)"
    tmpfile="$(mktemp -p "$tmpdir")"
    pipe1="$(mktemp -u -p "$tmpdir")"
    pipe2="$(mktemp -u -p "$tmpdir")"
    mkfifo "$pipe1" "$pipe2"
    monlang-parser/bin/main.elf\ -o < "$pipe1" & parser_pid=$!
    monlang-interpreter/bin/main.elf\ -i "$@" < "$pipe2" || { kill -9 $parser_pid; kill -15 $$; } &
    while true; do
        { tee "$tmpfile"; } &>/dev/null
        cat "$tmpfile" > "$pipe2"
        cat "$tmpfile" > "$pipe1"
    done

# stdin mode #
elif [ "$1" == "-" ]; then
    tmpdir="$(mktemp -d)"
    tmpfile="$(mktemp -p "$tmpdir")"
    replace_shebang > "$tmpfile"
    monlang-parser/bin/main.elf\ -o - < "$tmpfile"
    monlang-interpreter/bin/main.elf - "${@:2}" < "$tmpfile"

# filein mode #
else
    tmpdir="$(mktemp -d)"
    tmpfile="$(mktemp -p "$tmpdir")"
    replace_shebang < "$FILEPATH" > "$tmpfile"
    SRCNAME="$1" monlang-parser/bin/main.elf\ -o "$tmpfile"
    SRCNAME="$1" monlang-interpreter/bin/main.elf "$tmpfile" "${@:2}"

fi
