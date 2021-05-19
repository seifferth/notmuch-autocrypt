#!/bin/bash

get_header() {
    awk 'BEGIN           { output=1 }
         /^[ \t]*$/      { output=0 }
         output == 1     { print    }'
}
get_autocrypt_header() {
    awk 'BEGIN           { output=0 }
         /^[^ \t]/       { output=0 }
         /^Autocrypt:/   { output=1 }
         output == 1     { print    }'
}
# Filter a stream of files so that only files containing an autocrypt header
# remain.
has_autocrypt_header() {
    while read file; do
        cat "$file" |
            get_header |
            get_autocrypt_header |
            head -n1 | while read header; do echo "$file"; done
    done
}
# Validate that there is an autocrypt header, and that there is only one
# autocrypt header.
has_valid_autocrypt_header() {
    while read file; do
        cat "$file" |
            get_header |
            get_autocrypt_header |
            grep -i "^autocrypt:" |
            wc -l | grep -q '^1$' && echo "$file"
    done
}

get_message_id() {
    while read file; do
        cat "$file" |
            get_header |
            awk '  BEGIN           { IGNORECASE=1 }
                   /^message-id:/  { print $2 }     ' |
            sed 's,^<,,;s,>$,,'
    done
}

cd $(notmuch config get database.path)
id_log=$(mktemp)

grep -irl "^autocrypt:" |
    has_autocrypt_header |
    has_valid_autocrypt_header |
    get_message_id |
    sed 's,^,id:,' |
    tee "$id_log" |
    xargs -d'\n' notmuch tag +autocrypt

echo "Tagged $(cat "$id_log"|wc -l) messages with tag:autocrypt"
rm "$id_log"
