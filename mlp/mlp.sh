#!/bin/bash
set -o errexit
# set -o xtrace #debug

# protection against corrupted output file
trap '[ -f "$FILEOUT" ] && rm -f "$FILEOUT"' ERR

if [ "$1" == diff ]; then
    DIFFMODE=x
    shift
fi

if [ "$1" == -o ]; then
    FILEOUT="$2"
    [ "$FILEOUT" == "-" ] && FILEOUT="/dev/stdout"
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
[ -z "$DIFFMODE" ] && [ -f "$FILEOUT" ] && [ "$FILEOUT" -nt "$FILEIN" ] && {
    # protection against losing data
    >&2 echo "Output file has been updated, are you sure you want to overwrite it ?"
    >&2 echo -n "confirm?(Y/n) >"
    read confirm
    [[ "$confirm" =~ n|N ]] && { >&2 echo "aborted"; exit 0; }
}

[ -n "$DIFFMODE" ] && {
    if [ -f "$FILEOUT" ]; then
        exit_code=0
        git diff --no-index --no-prefix -U1000 <("$0" -o - "$FILEIN" $ARGS) "$FILEOUT" || {
            exit_code=$?
        }
    else
        exit_code=1
    fi
    exit $exit_code
}

perl preprocess.pl "$FILEIN" $ARGS > "$FILEOUT"

[ -f "$FILEOUT" ] && touch -r "$FILEIN" "$FILEOUT"

true
