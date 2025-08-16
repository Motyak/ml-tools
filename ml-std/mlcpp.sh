#!/bin/bash
set -o errexit
set -o pipefail
# set -o xtrace #debug

# protection against corrupted output file
trap '[ -f "$FILEOUT" ] && rm -f "$FILEOUT"' ERR

if [ "$1" == -o ]; then
    FILEOUT="$2"
    [[ "$FILEOUT" =~ ^-$ ]] && FILEOUT="/dev/stdout"
    FILEIN="$3"
    ARGS="${@:4:$#-1}"
else
    FILEIN="$1"
    FILEOUT="${1%.mlp}.ml"
    ARGS="${@:2:$#-1}"
fi

[[ "$FILEIN" =~ ".mlp"$ ]] || {
    >&2 echo "Invalid file extension: \`${FILEIN##*.}\`"
    exit 1
}

# for this to work, we align output file last modif date
# ..with input file's, at the time of preprocessing
[ -f "$FILEOUT" ] && [ "$FILEOUT" -nt "$FILEIN" ] && {
    # protection against losing data
    >&2 echo "Output file has been updated, are you sure you want to overwrite it ?"
    >&2 echo -n "confirm?(Y/n) >"
    read confirm
    [[ "$confirm" =~ n|N ]] && { >&2 echo "aborted"; exit 0; }
}

cpp_input="$(cat << EOF
#warning "=== STANDARD DEFINED MACROS ==="
$(awk '{print "#undef " $0}' standard_predefined_macros.txt)

#warning "=== COMMON DEFINED MACROS ==="
$(awk '{print "#undef " $0}' common_predefined_macros.txt)

#warning "=== OTHER DEFINED MACROS ==="
$(cpp -undef -dM <<< "" | awk '{print "#undef " $2}')

#define ESCAPE_CPP__
#define NULL_DIRECTIVE__ #
NULL_DIRECTIVE__
$(perl -pe 's/\\\n/\\ESCAPE_CPP__\n/gm' "$FILEIN" \
    | perl -pe 's/( {4,})#/$1ESCAPE_CPP__#/g')
EOF
)"

cpp_output="$(2>/dev/null cpp -w -undef -nostdinc -fpreprocessed -C -fdirectives-only $ARGS <<< "$cpp_input" || {
    exit_code=$?
    # report errors from file, instead of <stdin>
    cpp -w -undef -nostdinc $ARGS "$FILEIN"
    exit $exit_code
})"

perl -0pe 's/^package main\n.*?\n# /# /gms' <<< "$cpp_output" \
    | perl -pe 's/^package main\n/"package main"\n/gm' \
    | perl -pe 's/^package (\S+)\n//gm' \
    | perl preprocess_cpp_linemarkers.pl "$FILEIN" > "$FILEOUT"

[ -f "$FILEOUT" ] && touch -r "$FILEIN" "$FILEOUT"

true
