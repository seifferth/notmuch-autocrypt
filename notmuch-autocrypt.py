#!/usr/bin/env python3

from typing import Union
import subprocess, json, base64
import pgpy
import sys, os

def _verify_key_format(key: bytes, address: str) -> bytes:
    """
    Confirm that the key material conforms to the autocrypt spec and
    that the User ID packet matches the expected address. This second
    requirement is not mandated by autocrypt -- but since we might
    pass the key to tools like gpg that take the User ID at face value,
    it still makes sense to reject keys with a mismatched User ID.
    """
    d = bytearray(key); packets = []
    while len(d) > 0:
        packets.append(pgpy.packet.Packet(d))
    # FIXME: Add support for V6 public keys as well
    if len(packets) != 5:
        raise Exception('Wrong number of packets')
    if type(packets[0]) != pgpy.packet.packets.PubKeyV4:
        raise Exception('Packet 0 must be a PubKeyV4 packet')
    if type(packets[1]) != pgpy.packet.packets.UserID:
        raise Exception('Packet 1 must be a UserID packet')
    if type(packets[2]) != pgpy.packet.packets.SignatureV4:
        raise Exception('Packet 2 must be a SignatureV4 packet')
    if type(packets[3]) != pgpy.packet.packets.PubSubKeyV4:
        raise Exception('Packet 3 must be a PubSubKeyV4 packet')
    if type(packets[4]) != pgpy.packet.packets.SignatureV4:
        raise Exception('Packet 4 must be a SignatureV4 packet')
    if not packets[1].uid.endswith(f'<{address}>'):
        raise Exception('User ID does not match expected address')
    return key
def locate_single_key(address: str) -> Union[bytes|None]:
    mid = subprocess.run(
        ['notmuch', 'search', '--limit=1', '--output=messages',
         f'tag:autocrypt and from:{address}'],
        text=True, capture_output=True,
    ).stdout.strip()
    if not mid: return None
    msg = json.loads(subprocess.run(
        ['notmuch', 'show', '--format=json', '--part=0', mid],
        text=True, capture_output=True,
    ).stdout.strip())
    if not msg['headers']['Autocrypt'].startswith(f'addr={address};'):
        raise Exception("Wrong 'addr' specified in autocrypt header")
    keydata = msg['headers']['Autocrypt'].rsplit('keydata=', 1)[1]
    return _verify_key_format(base64.b64decode(keydata), address)

def decrypt_setup_message(filename, passphrase) -> bytes:
    secret_key = subprocess.run(
        ['gpg', '--batch', '--decrypt', '--passphrase-fd', '0', filename],
        capture_output=True, input=passphrase.encode('ascii'),
    ).stdout
    return secret_key

_cli_help = """
Usage: notmuch autocrypt COMMAND [COMMAND-ARGS]

Commands
    --locate-keys EMAIL...
            Search for autocrypt headers in recent messages from EMAIL.
            If such headers are found, the public keys stored in those
            headers will automatically be imported into the gpg keyring.
    --import-secret-key SETUP-MESSAGE [PASSPHRASE]
            Decrypt the setup message found in the file provided as
            the first argument and import the secret key into the gpg
            keyring. If no passphrase is provided, the user will be
            prompted interactively.
    -h, --help
            Print this help message and exit.
""".lstrip()

if __name__ == '__main__':
    if sys.argv[1] in ['-h', '--help']:
        print(_cli_help)
    elif sys.argv[1] == '--locate-keys':
        if len(sys.argv) < 3:
            exit('Missing argument EMAIL')
        for address in sys.argv[2:]:
            key = locate_single_key(address)
            if key == None:
                print("No key found for '{address}'", file=sys.stderr)
            else:
                subprocess.run(['gpg', '--import'], input=key)
    elif sys.argv[1] == '--import-secret-key':
        if len(sys.argv) < 3:
            exit('Missing argument SETUP-MESSAGE')
        elif len(sys.argv) > 4:
            exit('Too many arguments')
        filename = sys.argv[2]
        if not os.path.isfile(filename):
            exit(f"No such file '{filename}'")
        if len(sys.argv) < 4:
            passphrase = input('Passphrase: ')
        else:
            passphrase = sys.argv[3]
        secret_key = decrypt_setup_message(filename, passphrase)
        subprocess.run(['gpg', '--import'], input=secret_key)
    else:
        exit(f"Unknown command '{sys.argv[1]}'")
