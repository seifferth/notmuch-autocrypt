#!/bin/bash
set -e

account_init() {
#include account_init.sh $@
echo "It looks like you're running a non-compiled version " \
     "of notmuch-autocrypt" | fmt >&2
exit 120
#endinclude
}
account_get() {
#include account_get.sh $@
echo "It looks like you're running a non-compiled version " \
     "of notmuch-autocrypt" | fmt >&2
exit 120
#endinclude
}
peer_get() {
#include peer_get.sh $@
echo "It looks like you're running a non-compiled version " \
     "of notmuch-autocrypt" | fmt >&2
exit 120
#endinclude
}
recommend() {
#include recommend.sh $@
echo "It looks like you're running a non-compiled version " \
     "of notmuch-autocrypt" | fmt >&2
exit 120
#endinclude
}

help() {
cat <<EOF
Usage: notmuch-autocrypt account init <email>
       notmuch-autocrypt account get <email> [field]
       notmuch-autocrypt peer get <email> [field]
       notmuch-autocrypt recommend <email> [email]...

EOF
}

if test "$#" -lt 1; then
    help >&2
    exit 1
fi

IFS=""
# Parse main argument
if test "$1" = "account" && test "$2" = "init"; then
    shift 2; account_init $@; exit $?
elif test "$1" = "account" && test "$2" = "get"; then
    shift 2; account_get $@; exit $?
elif test "$1" = "peer" && test "$2" = "get"; then
    shift 2; peer_get $@; exit $?
elif test "$1" = "recommend"; then
    shift 1; recommend $@; exit $?
elif test "$1" = "-h" || test "$1" = "--help" || test "$1" = "help"; then
    help >&1; exit 0
else
    echo "Unsupported arguments '$@'" >&2; exit 1
fi
