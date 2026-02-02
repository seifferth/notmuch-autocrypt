#!/usr/bin/env python3

from typing import Union
import subprocess, json
import sys

def last_seen(address: str) -> Union[int|None]:
    mid = subprocess.run(
        ['notmuch', 'search', '--limit=1', '--output=messages',
         f'from:{address}'],
        text=True, capture_output=True,
    ).stdout.strip()
    if not mid: return None
    return json.loads(subprocess.run(
        ['notmuch', 'show', '--format=json', '--part=0', mid],
        text=True, capture_output=True,
    ).stdout.strip())['timestamp']
def autocrypt_timestamp(address: str) -> Union[int|None]:
    mid = subprocess.run(
        ['notmuch', 'search', '--limit=1', '--output=messages',
         f'from:{address} and tag:autocrypt'],
        text=True, capture_output=True,
    ).stdout.strip()
    if not mid: return None
    return json.loads(subprocess.run(
        ['notmuch', 'show', '--format=json', '--part=0', mid],
        text=True, capture_output=True,
    ).stdout.strip())['timestamp']
def prefer_encrypt(address: str) -> Union['mutual', 'nopreference']:
    mid = subprocess.run(
        ['notmuch', 'search', '--limit=1', '--output=messages',
         f'from:{address} and tag:autocrypt'],
        text=True, capture_output=True,
    ).stdout.strip()
    autocrypt_header = json.loads(subprocess.run(
        ['notmuch', 'show', '--format=json', '--part=0', mid],
        text=True, capture_output=True,
    ).stdout.strip())['headers']['Autocrypt']
    if 'prefer-encrypt=mutual' in autocrypt_header:
        return 'mutual'
    else:
        return 'nopreference'
def autocrypt_key_available(address: str) -> bool:
    mid = subprocess.run(
        ['notmuch', 'search', '--limit=1', '--output=messages',
         f'from:{address} and tag:autocrypt'],
        text=True, capture_output=True,
    ).stdout.strip()
    return True if mid else False
def gossip_key_available(address: str) -> bool:
    # FIXME: Update this query once gossip keys are supported
    return False

def _single_ui_recommendation(
                address: str,
                encrypted_parent: Union['true', 'false'],
                sender_prefer_encrypt: Union['mutual', 'nopreference']
            ) -> Union['disable', 'discourage', 'available', 'encrypt']:
    if not autocrypt_key_available(address) and \
       not gossip_key_available(address):
        return 'disable'
    if not autocrypt_key_available(address) and \
       gossip_key_available(address):
        preliminary = 'discourage'
    elif autocrypt_timestamp(address) != None and \
         last_seen(address) != None and \
         autocrypt_timestamp(address) < last_seen(address) and \
         abs(last_seen(address) - autocrypt_timestamp(address)) > 35*24*60*60:
        preliminary = 'discourage'
    else:
        preliminary = 'available'
    if preliminary in ['available', 'discourage'] and \
       encrypted_parent == 'true':
        return 'encrypt'
    elif preliminary in ['available', 'discourage'] and \
         prefer_encrypt(address) == 'mutual' and \
         sender_prefer_encrypt == 'mutual':
        return 'encrypt'
    else:
        return preliminary
def provide_ui_recommendation(
                recipients: list[str],
                encrypted_parent: Union['true', 'false'],
                sender_prefer_encrypt: Union['mutual', 'nopreference']
            ) -> Union['disable', 'discourage', 'available', 'encrypt']:
    if len(set(recipients)) == 1:
        return _single_ui_recommendation(recipients[0],
                                         encrypted_parent,
                                         sender_prefer_encrypt)
    else:
        all_recommendations = [ _single_ui_recommendation(address,
                                    encrypted_parent, sender_prefer_encrypt)
                                for address in set(recipients) ]
        if 'disable' in all_recommendations:            return 'disable'
        elif set(all_recommendations) == {'encrypt'}:   return 'encrypt'
        elif 'discourage' in all_recommendations:       return 'discourage'
        else:                                           return 'available'

_cli_help = """
Usage: ./provide_ui_recommendation.py [--help] [SETTING|EMAIL]...

Settings
    encrypted-parent=[true|false]
        Specify whether the message in question is a reply to an
        end-to-end encrypted message. Default: false.
    sender-prefer-encrypt=[mutual|nopreference]
        Specify whether the sender themselves have a prefer-encrypt
        setting of mutual or of nopreference. Default: nopreference.
""".lstrip()

if __name__ == '__main__':
    recipients = list()
    sender_prefer_encrypt = 'nopreference'
    encrypted_parent = 'false'
    if len(sys.argv) == 1:
        exit(_cli_help)
    for arg in sys.argv[1:]:
        if arg in ['-h', '--help', 'help']:
            print(_cli_help); exit(0)
        elif '@' in arg:
            recipients.append(arg)
        elif arg == 'sender-prefer-encrypt=nopreference':
            sender_prefer_encrypt = 'nopreference'
        elif arg == 'sender-prefer-encrypt=mutual':
            sender_prefer_encrypt = 'mutual'
        elif arg == 'encrypted-parent=true':
            encrypted_parent = 'true'
        elif arg == 'encrypted-parent=false':
            encrypted_parent = 'false'
        else:
            exit(f"Unsupported argument '{arg}'")
    print(provide_ui_recommendation(recipients,
                                    encrypted_parent,
                                    sender_prefer_encrypt))
