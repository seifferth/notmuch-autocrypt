# notmuch-autocrypt

A very hackish bash-implementation of autocrypt for the notmuch email
system. This implementation is not meant to ever be used as an actual
production-ready autocrypt implementation. It is simply a personal
playground for quickly trying out some ideas on how to implement autocrypt
in notmuch. If those ideas work out, I'd hope to see them implemented in
a proper language, maybe even as a native part of notmuch.

## Dependencies

- bash and a common POSIX environment (featuring sed, awk, ...)
- gpg
- notmuch

## Compiling

`notmuch-autocrypt` is compiled into a single, self-contained bash script
at `out/notmuch-autocrypt`. Simply run `make` to compile it.

## Usage

TODO

## Key storage

The autocrypt specification states that

> The MUA MAY protect the secret key (and other sensitive data it has
> access to) with a password, but it SHOULD NOT require the user to
> enter the password each time they send or receive a mail. [...]
> Protection of the user’s keys (and other sensitive data) at rest
> is achieved more easily and securely with filesystem-based encryption
> and other forms of access control.

This implementation stores all keys and configuration without encryption
below `~/.config/notmuch-autocrypt`. If security is a concern, make sure
to use other means to appropriately protect that directory.

## Author

Frank Seifferth <frankseifferth@posteo.net>. Feel free to contact me
with feedback or suggestions.
