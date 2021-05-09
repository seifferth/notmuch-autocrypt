#!/bin/bash
#
# Usage account_init.sh <account>

if ! test "$1"; then
    echo "Missing account" >&2
    exit 1
fi

conf_dir="$HOME/.config/notmuch-autocrypt/$1"
if test -d $conf_dir; then
    echo "Account '$1' has already been initialized" >&2
    exit 1
fi

mkdir -p "$conf_dir"
cat <<EOF > "$conf_dir/config"
enabled=true
prefer_encrypt=mutual
EOF

mkdir -m 700 "$conf_dir/gpg"
gpg \
    --homedir "$conf_dir/gpg" \
    --batch \
    --passphrase '' \
    --quick-generate-key "$1" "ed25519/cert,sign+cv25519/encr"
gpg \
    --homedir "$conf_dir/gpg" \
    --export "$1" | base64 -w0 > "$conf_dir/public_key"
echo >> "$conf_dir/public_key"  # Add final newline
gpg \
    --homedir "$conf_dir/gpg" \
    --export --armor "$1" > "$conf_dir/public_key.ascii"
gpg \
    --homedir "$conf_dir/gpg" \
    --export-secret-keys "$1" | base64 -w0 > "$conf_dir/secret_key"
echo >> "$conf_dir/secret_key"  # Add final newline
gpg \
    --homedir "$conf_dir/gpg" \
    --export-secret-keys --armor "$1" > "$conf_dir/secret_key.ascii"
