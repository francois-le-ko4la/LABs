#!/opt/rubrik/scripts/venv/bin/python3
# -*- coding: utf-8 -*-
# DISCLAIMER:
# This script is developed for demonstration purposes only and should be used
# with caution. Always ensure the security of your data and use appropriate
# encryption methods in production environments.

# setup:
#   $ python3 -m venv /opt/rubrik/scripts/venv
#   $ /opt/rubrik/scripts/venv/bin/python -m pip install cryptography
#
# Example:
#   $ ./encrypt_file.py --delete-original encrypt key file/
#   $ ./encrypt_file.py --delete-original decrypt key file/

import os
import argparse
from cryptography.fernet import Fernet


def load_key(key_file):
    """Load encryption key from a file"""
    with open(key_file, 'rb') as file:
        return file.read()

def encrypt_file(file_path, key):
    """Encrypt a file with the given key"""
    f = Fernet(key)
    with open(file_path, 'rb') as file:
        data = file.read()
    encrypted_data = f.encrypt(data)
    with open(file_path + '.encrypted', 'wb') as encrypted_file:
        encrypted_file.write(encrypted_data)

def decrypt_file(encrypted_file_path, key):
    """Decrypt an encrypted file with the given key"""
    f = Fernet(key)
    with open(encrypted_file_path, 'rb') as encrypted_file:
        encrypted_data = encrypted_file.read()
    decrypted_data = f.decrypt(encrypted_data)
    with open(encrypted_file_path[:-len('.encrypted')], 'wb') as decrypted_file:
        decrypted_file.write(decrypted_data)

def process_directory(directory, key, encrypt=True, delete_original=False):
    """Process files in a directory recursively"""
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            if encrypt:
                encrypt_file(file_path, key)
            else:
                decrypt_file(file_path, key)
            if delete_original:
                os.remove(file_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Encrypt or decrypt files in a directory recursively using a given key")
    parser.add_argument("action", choices=["encrypt", "decrypt"], help="Specify whether to encrypt or decrypt files")
    parser.add_argument("key_file", help="Path to the file containing the encryption key")
    parser.add_argument("directory", help="Path to the directory to process")
    parser.add_argument("--delete-original", action="store_true", help="Delete original files after encryption/decryption")
    args = parser.parse_args()

    # Load the encryption key from the specified file
    key = load_key(args.key_file)

    # Process files in the specified directory
    process_directory(args.directory, key, encrypt=args.action == "encrypt", delete_original=args.delete_original)

    print("Operation completed successfully.")
