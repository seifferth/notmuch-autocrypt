#!/bin/bash
#
# Usage: recommend.sh <to-address> [to-address]...
#
# You can also set the environment variable REPLY_TO_ENCRYPTED to let
# recommend.sh know that you are replying to an encrypted message, which
# in turn influences the suggestion.

# Recommendation (r) can be any of
#   - disable
#   - discourage
#   - available
#   - encrypt
r="encrypt"

# Usage: is_too_old <autocrypt_timestamp> <last_seen>
is_too_old() {
    test $((
            $((
               $(date --date="$2" +%s) - $(date --date="$1" +%s)
            ))/$((60*60*24))
          )) -gt 35
}

set_r() {
    if test "$1" = "disable"; then
        r="disable"
    elif test "$1" = "available"; then
        if test "$r" = "encrypt"; then
            r="available"
        fi
    elif test "$1" = "discourage"; then
        if test "$r" = "available" || test "$r" = "encrypt"; then
            r="discourage"
        fi
    elif test "$1" = "encrypt"; then
        if test "$r" = "encrypt"; then
            r="encrypt"
        fi
    else
        exit 25
    fi
}

for x in $@; do
    last_seen="$(notmuch autocrypt peer get "$x" last_seen)"
    autocrypt_timestamp="$(notmuch autocrypt peer get "$x" \
                                                autocrypt_timestamp)"
    prefer_encrypt="$(notmuch autocrypt peer get "$x" prefer_encrypt)"
    public_key="$(notmuch autocrypt peer get "$x" public_key)"

    if ! test "$public_key"; then
        prelim=disable
    elif is_too_old $autocrypt_timestamp $last_seen; then
        prelim=discourage
    else
        prelim=available
    fi

    if test "$prelim" = disable; then
        set_r disable
    elif test "$prelim" = available || test "$prelim" = discourage; then
        if test "$prefer_encrypt" = "mutual" ||
           test "$REPLY_TO_ENCRYPTED"; then
            set_r encrypt
        else
            set_r $prelim
        fi
    else
        set_r $prelim
    fi
    
done

echo $r
