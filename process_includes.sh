#!/bin/bash
#
# Substitute include statements with here-docs. This allows us to compile
# multiple input files into a self-contained bash script. See main.sh for
# hints on how to use include statements.

set -e

IFS=""
mode=normal
while read -r line; do
    if test "$mode" == "include"; then
        if echo "$line" | grep -q '^#endinclude'; then
            mode=normal
        fi
    elif echo "$line" | grep -q '^#include'; then
        mode=include
        file="$(echo "$line"|sed 's,^#include *\([^ ]*\).*$,\1,g')"
        args="$(echo "$line"|
                    sed 's, \+,\n,g'|
                    tail -n+3|
                    tr '\n' ' '|sed 's, $,,g'
             )"
        if ! test -f "$file"; then
            echo "Cannot find included file: '$file'" >&2
            exit 1
        fi
        shebang="$(head -n1 "$file"|grep '^#!'|sed 's,^#!,,g')"
        if ! test "$shebang"; then
            echo "'$file' does not contain a valid shebang" >&2
            exit 1
        fi
        hash="$(md5sum "$file"|sed 's, .*$,,g')"
        if grep -q "$hash" "$file"; then
            echo "Congratulations! '$file' contains its own md5sum." \
                 "This compiler can't process files containing their" \
                 "own md5sum. (What's the chance, right?)" | fmt >&2
            exit 1
        fi
        echo "$shebang <("
        echo "cat <<\"$hash\""
        cat "$file"
        echo "$hash"
        echo ") $args" | sed 's, $,,g'
    else
        echo "$line"
    fi
done
