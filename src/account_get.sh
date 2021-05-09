#!/bin/bash
#
# Usage: account_get.sh <account> [field]

account="$1"
field="$2"

enabled=""
secret_key=""
public_key=""
prefer_encrypt=""

conf_dir="$HOME/.config/notmuch-autocrypt/$account"
test -d "$conf_dir" || exit 1

get_config_value() {
    cat "$conf_dir/config" |
        sed 's,[ \t]*#.*,,g' |
        grep "^[ \t]*$1[ \t]*=" |
        sed "s,^[ \t]*$1[ \t]*=[ \t]*\(.*\)$,\1,g"
}
enabled="$(get_config_value enabled)"
prefer_encrypt="$(get_config_value prefer_encrypt)"
test -f "$conf_dir/secret_key" &&
    secret_key="$(cat "$conf_dir/secret_key")"
test -f "$conf_dir/public_key" &&
    public_key="$(cat "$conf_dir/public_key")"

extract_field() {
    grep "^$1=" | sed "s,^$1=,,g"
}
cat <<EOF | if test "$2"; then extract_field "$2"; else cat; fi
enabled=$enabled
secret_key=$secret_key
public_key=$public_key
prefer_encrypt=$prefer_encrypt
EOF
