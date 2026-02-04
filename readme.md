# notmuch-autocrypt

[Autocrypt](https://docs.autocrypt.org/) is a new-ish (2019) standard
for distributing OpenPGP public keys in email headers in order to enable
opportunistic end-to-end encryption for email. The actual autocrypt spec
talks a lot about MUAs keeping a peer state table. An alternative way
of conceptualizing autocrypt -- and one that would arguably be closer
to how notmuch conceptualizes email -- would be to view the email
database itself as an OpenPGP key store. The 'notmuch-autocrypt.py' script
provided in this repository takes this second view and allows users to
conveniently import autocrypt keys from their email database into their
gpg keyring. While this does not turn notmuch into a standards-compliant
autocrypt client just yet, it should be enough to bring the key benefit
of autocrypt to any notmuch- and gpg-based email setup.

The 'notmuch-autocrypt.py' script provides two main functions through
a gpg-inspired command line interface:

`notmuch autocrypt --locate-keys EMAIL...`
: Import the public key found in the most recent autocrypt header sent by
  `EMAIL` into the gpg keyring. This command is roughly equivalent to
  how one would use `gpg --locate-external-keys` to import keys from a
  Web Key Directory, for instance.

`notmuch autocrypt --import-secret-key SETUP-MESSAGE [PASSPHRASE]`
: Import the secret key found in `SETUP-MESSAGE` into the gpg keyring.
  This command is useful for configuring notmuch and gpg in a multi-client
  autocrypt setup.


## Computing the UI Recommendation

The autocrypt spec also specifies an algorithm that can optionally be
used to compute a recommendation for whether or not a message should
be encrypted. This algorithm depends both on the state of the 'peers'
table and on the user's autocrypt settings and will always output one
of the following four values: 'disable', 'discourage', 'available', and
'encrypt'. Since computing this recommendation is somewhat involved,
the implementation of this algorithm has not been included in the main
'notmuch-autocrypt.py' script and is instead provided as a standalone
script named 'provide_ui_recommendation.py'. This reference implementation
is provided as a proof of concept that shows how the ui-recommendation
could be computed by using queries against a notmuch database rather
than by maintaining a peers table. As of now, this implementation is
not 100 % feature complete yet, as it does not take the keydata itself
(especially: key expiry or key revocation) into account. However, this
data is already queried to determine whether a key exists at all --
so extending the implementation to also check the expiry date should be
fairly straightforward. Also note that the implementation is far from
optimized, so frontends that wish to make use of the ui-recommendation
might prefer to use their own implementation instead. For usage
information see `./provide_ui_recommendation.py --help`.


## Dependencies

* A patched version of notmuch (available at
  https://github.com/seifferth/notmuch as branch 'autocrypt')
* python3-pgpy
* gpg


## Limitations

1. Autocrypt uses a very restricted subset of OpenPGP. Most notably, it
   supposes that each user has only two keys. One primary key used for
   generating signatures and one subkey used for encryption. In order
   to prevent incompatibilities between gpg and autocrypt-compatible
   email clients that do not implement the full set of options provided
   by OpenPGP, it might be a good idea to use gpg with a private keyring
   that only contains a single, autocrypt-compatible identity.

2. There is currently no support for generating autocrypt-compatible
   key pairs with 'notmuch-autocrypt'. Since autocrypt-compatible keys
   are simply a very limited subset of all possible OpenPGP keys, it
   should be rather easy to provide a command like `notmuch autocrypt
   --generate-key` that simply wraps `gpg --quick-generate-key` using the
   correct autocrypt-specific settings. If anyone should be interested
   in testing such a feature, please drop me a note.

3. There is also no support for generating autocrypt setup messages with
   'notmuch-autocrypt'. Generating setup messages probably only makes
   sense once 'notmuch-autocrypt' can also generate key pairs; and
   adding such a feature would require at least some integration tests
   with other autocrypt-compatible email clients. However, if anyone
   should be interested in performing such tests, I would be happy to
   add a command like `notmuch autocrypt --generate-setup-message`.

4. Finally, 'notmuch-autocrypt' does not take care of adding autocrypt
   headers to outbound email. Since modifying outbound email is beyond
   the scope of what notmuch is supposed to do, it would also make little
   sense to try and add this feature to 'notmuch-autocrypt'. On the other
   hand, autocrypt headers are basically just static strings that are
   added to each outbound message. It should therefore be fairly easy to
   add support for autocrypt headers to the various notmuch frontends.
   The autocrypt header only contains the sender's email address,
   an optional 'prefer-encrypt' setting and a base64-encoded OpenPGP
   public key referred to as 'keydata' in the autocrypt spec. This
   'keydata' can be generated by running `gpg --export PUBKEY | base64`;
   provided that `PUBKEY` is a minimized OpenPGP key that fulfils the
   requirements outlined in the autocrypt specification. I suspect that
   the easiest way of adding support for sending autocrypt headers to a
   notmuch frontend would be to add a configuration option that stores
   this base64-encoded public key. However, I would also be open to
   discuss this point further if anyone should see the need.


## License

All files contained in this repository are licensed under the terms
of the GNU General Public License, version 3 or later. A copy of this
license is included in the repository as `license.txt`.
