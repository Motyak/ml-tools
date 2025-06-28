#!/bin/bash
set -o errexit

function LV1 {
    cd monlang/include/monlang; find -P ~+ -not -name '.*' -name '*.h'; >/dev/null cd -
    cd monlang/src; find -P ~+ -maxdepth 1 -not -name '.*' -name '*.cpp'; >/dev/null cd -
    cd monlang/src/ast; find -P ~+ -not -name '.*' -name '*.cpp'; >/dev/null cd -
    cd monlang/tools; find -P ~+ -not -name '.*' -name '*.sh'; >/dev/null cd -
    cd monlang; find -P ~+ -maxdepth 1 -type f -not -name '.*' \
        -not -name 'env.sh' \
        -not -name 'utils.mk' \
        -not -name 'notes.txt' \
        -not -name 'init_priority.txt' \
    ; >/dev/null cd -
}

function LV2 {
    cd monlang-parser/monlang-LV2/include/monlang-LV2; find -P ~+ -not -name '.*' -name '*.h'; >/dev/null cd -
    cd monlang-parser/monlang-LV2/src; find -P ~+ -maxdepth 1 -not -name '.*' -name '*.cpp'; >/dev/null cd -
    cd monlang-parser/monlang-LV2/src/expr; find -P ~+ -not -name '.*' -name '*.cpp'; >/dev/null cd -
    cd monlang-parser/monlang-LV2/src/stmt; find -P ~+ -not -name '.*' -name '*.cpp'; >/dev/null cd -
    cd monlang-parser/monlang-LV2; find -P ~+ -maxdepth 1 -type f -not -name '.*' \
        -not -name 'env.sh' \
        -not -name 'utils.mk' \
        -not -name 'notes.txt' \
        -not -name 'stub.txt' \
    ; >/dev/null cd -
}

function montree {
    cd monlang-parser/montree/include/montree; find -P ~+ -not -name '.*' -name '*.h'; >/dev/null cd -
    cd monlang-parser/montree/src; find -P ~+ -not -name '.*' -name '*.cpp'; >/dev/null cd -
    cd monlang-parser/montree; find -P ~+ -maxdepth 1 -type f -not -name '.*' \
        -not -name 'env.sh' \
        -not -name 'utils.mk' \
    ; >/dev/null cd -
}

function utils {
    cd monlang-parser/common; find -P ~+ -type f -not -name '.*'; >/dev/null cd -
}

function parser {
    cd monlang-parser/include/monlang-parser; find -P ~+ -not -name '.*' -name '*.h'; >/dev/null cd -
    cd monlang-parser/src; find -P ~+ -maxdepth 1 -not -name '.*' -name '*.cpp'; >/dev/null cd -
    cd monlang-parser/tools; find -P ~+ -maxdepth 1 -name 'mrproper.sh'; >/dev/null cd -
    cd monlang-parser; find -P ~+ -maxdepth 1 -type f -not -name '.*' \
        -not -name 'env.sh' \
        -not -name 'utils.mk' \
        -not -name 'notes.txt' \
        -not -name 'token.err_start.txt' \
        -not -name 'cloc.sh' \
    ; >/dev/null cd -
}

function interpreter {
    cd monlang-interpreter/include/monlang-interpreter; find -P ~+ -not -name '.*' -name '*.h'; >/dev/null cd -
    cd monlang-interpreter/src; find -P ~+ -not -name '.*' -name '*.cpp'; >/dev/null cd -
    cd monlang-interpreter; find -P ~+ -maxdepth 1 -type f -not -name '.*' \
        -not -name 'env.sh' \
        -not -name 'utils.mk' \
        -not -name 'notes.txt' \
        -not -name 'init_priority.txt' \
        -not -name 'monlang-LV1.env.sh' \
    ; >/dev/null cd -
}

function server {
    cd monlang-server; find -P ~+ -maxdepth 1 -type f -not -name '.*' \
        -not -name 'notes.txt' \
        -not -name 'LV1.ERR.txt' \
        -not -name 'LV2.ERR.txt' \
    ; >/dev/null cd -
}

function ml_tools {
    find -P ~+ -maxdepth 1 -type f -not -name '.*' \
        -not -name 'testshebang.ml' \
        -not -name 'filelist.txt'
}

########################################################

function doit {
    cat /dev/null > filelist.txt
    for module in "$@"; do
        $module >> filelist.txt
    done
    var="$(cloc --list-file=filelist.txt --by-file | perl -pe 's/^.*ml-tools/./g')"
    sum_row="$(tail -n2 <<< "$var" | head -n2)"
    table="$(tail -n+2 <<< "$var")"
    tac <<< "$table"
    echo "$sum_row"
}

trap 'rm -f filelist.txt' EXIT

MODULES="$@"

[ "$MODULES" == "" ] && {
    doit LV1 LV2 montree utils parser interpreter server ml_tools
    exit 0
}

doit $MODULES
