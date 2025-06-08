# notmuch-autocrypt

These are some very hackish scripts for using autocrypt keys with notmuch
and gpg. They are very far from being an actual implementation. Still,
they might come handy to people who use multi-client email setups where
some of their email clients are autocrypt-capable. Currently, this repo
contains the following scripts:

`notmuch-autocrypt-lookup <PEER-ADDRESS>`
: Look for an autocrypt header in recent messages from `PEER-ADDRESS`
  and, if found, import the public key into the gpg keyring.

`notmuch-autocrypt-setup <SETUP-MESSAGE> [PASSPHRASE]`
: Import the private key from the autocrypt setup message `SETUP-MESSAGE`
  into the gpg keyring. If no passphrase is provided, the user will be
  prompted interactively. Note that this command should not be run on
  a multi-user system as it invokes gpg with the `--passphrase` option.


## License

The scripts in this repository are licensed under hte terms of the GNU
General Public License, version 3 or later. A copy of this license is
included in the repository as `license.txt`.
