#!/bin/bash
#
# Usage: peer_get.sh <peer> [field]

peer="$1"
field="$2"

last_seen=""
autocrypt_timestamp=""
public_key=""
prefer_encrypt=""

get_header() {
    cat "$1" |
        awk 'BEGIN           { output=1 }
             /^[ \t]*$/      { output=0 }
             output == 1     { print    }'
}
get_autocrypt_header() {
    get_header "$1" |
        awk 'BEGIN           { output=0 }
             /^[^ \t]/       { output=0 }
             /^Autocrypt:/   { output=1 }
             output == 1     { print    }'
}
get_autocrypt_value() {
    get_autocrypt_header "$2" |
        tr -d '\n \t' |
        sed 's,^Autocrypt:,,g' |
        tr ';' '\n' |
            if test "$1"; then
                grep "^$1=" | sed "s,^$1=,,g"
            else cat;echo; fi
}
get_message_date() {
    d="$(get_header "$1"|grep '^Date:'|head -n1|sed 's,^Date:[ \t]*,,g')"
    # Ensure there is a valid date field in this message
    test "$d" || return 1
    # Ensure the date lies in the past
    test "$(date --date="$d" -u +%s)" -le "$(date -u +%s)" || return 1
    date -u --date="$d" +'%F %T'
}

# Validate that there is an autocrypt header, and that there is only one
# autocrypt header.
has_valid_autocrypt_header() {
    get_autocrypt_header "$1" |
        grep '^Autocrypt:' |
        wc -l | grep -q '^1$' || return 1
}

# Done:
#   - Ignore multipart/report
#   - Ignore possible "spam" (assuming the user tags it as "spam")
# TODO:
#   - Ignore messages with more than one "From" header. I am not sure
#     if this is already handled or not.
files="$(notmuch search \
            --output=files \
            --sort=newest-first \
            from:"$peer" not mimetype:multipart/report not tag:spam
        )"
for f in $files; do
    test -f "$f" || exit 1
    test "$last_seen" || last_seen="$(get_message_date "$f")"
    if has_valid_autocrypt_header "$f"; then
        autocrypt_timestamp="$(get_message_date "$f")"
        public_key="$(get_autocrypt_value keydata "$f")"
        prefer_encrypt="$(get_autocrypt_value prefer-encrypt "$f")"
        test "$prefer_encrypt" || prefer_encrypt="nopreference"
        break
    fi
done

extract_field() {
    grep "^$1=" | sed "s,^$1=,,g"
}
cat <<EOF | if test "$2"; then extract_field "$2"; else cat; fi
last_seen=$last_seen
autocrypt_timestamp=$autocrypt_timestamp
prefer_encrypt=$prefer_encrypt
public_key=$public_key
EOF
