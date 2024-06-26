#!/opt/rubrik/scripts/venv/bin/python3
# -*- coding: utf-8 -*-
#
# DESCRIPTION:
# This script sets up a demo to demonstrate Rubrik Anomaly Detection/Threat Hunting.
#
# DISCLAIMER:
# This script is developed for demonstration purposes only and should be used
# with caution. Always ensure the security of your data and use appropriate
# encryption methods in production environments.
# This script is not supported under any support program or service. 
# All scripts are provided AS IS without warranty of any kind. 
# The author further disclaims all implied warranties including, without
# limitation, any implied warranties of merchantability or of fitness for a
# particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. 
# In no event shall its authors, or anyone else involved in the creation,
# production, or delivery of the scripts be liable for any damages whatsoever 
# (including, without limitation, damages for loss of business profits, business
# interruption, loss of business information, or other pecuniary loss) 
# arising out of the use of or inability to use the sample scripts or documentation,
# even if the author has been advised of the possibility of such damages.
#
# REQUIREMENTS:
# - Linux platform: Debian 7+, Ubuntu 20/04+, RHEL 8+ or CentOS 9+
# - python 3.6+
#
# SETUP:
#   $ python3 -m venv /opt/rubrik/scripts/venv
#   $ /opt/rubrik/scripts/venv/bin/python -m pip install cryptography
#   or
#   sudo curl https://raw.githubusercontent.com/francois-le-ko4la/LABs/main/ransim.sh | sudo sh
#
# EXAMPLE:
#   $ ./encrypt_file.py --delete-original encrypt key file/
#   $ ./encrypt_file.py --delete-original decrypt key file/
#
# CRONTAB EXAMPLE:
# 0 4 * * * /opt/rubrik/scripts/encrypt_file.py --delete-original encrypt /opt/rubrik/scripts/key /path/to/files
# 0 8 * * * /opt/rubrik/scripts/encrypt_file.py --delete-original decrypt /opt/rubrik/scripts/key /path/to/files
# 0 12 * * * /opt/rubrik/scripts/encrypt_file.py --delete-original encrypt /opt/rubrik/scripts/key /path/to/files
# 0 16 * * * /opt/rubrik/scripts/encrypt_file.py --delete-original decrypt /opt/rubrik/scripts/key /path/to/files
# 0 20 * * * /opt/rubrik/scripts/encrypt_file.py --delete-original encrypt /opt/rubrik/scripts/key /path/to/files
# 59 23 * * * /opt/rubrik/scripts/encrypt_file.py --delete-original decrypt /opt/rubrik/scripts/key /path/to/files
#
# YARA RULE EXAMPLE:
# import "hash"
#
# rule StringMatch : Crypto {
#  meta:
#    description = "cryptography library"
#  strings:
#    $crypto_lib = "from cryptography"
#  condition:
#    $crypto_lib and
#    filesize < 20KB
# }
#

import os
import argparse
import logging
from cryptography.fernet import Fernet
import datetime


__ascii_art__ = """

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⠶⠶⠶⠶⢦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠛⠁⠀⠀⠀⠀⠀⠀⠈⠙⢷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠸⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⣠⡴⠞⠛⠉⠉⣩⣍⠉⠉⠛⠳⢦⣄⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡀⠀⣴⡿⣧⣀⠀⢀⣠⡴⠋⠙⢷⣄⡀⠀⣀⣼⢿⣦⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣧⡾⠋⣷⠈⠉⠉⠉⠉⠀⠀⠀⠀⠉⠉⠋⠉⠁⣼⠙⢷⣼⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣇⠀⢻⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡟⠀⣸⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣹⣆⠀⢻⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡟⠀⣰⣏⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⠞⠋⠁⠙⢷⣄⠙⢷⣀⠀⠀⠀⠀⠀⠀⢀⡴⠋⢀⡾⠋⠈⠙⠻⢦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠋⠀⠀⠀⠀⠀⠀⠹⢦⡀⠙⠳⠶⢤⡤⠶⠞⠋⢀⡴⠟⠀⠀⠀⠀⠀⠀⠙⠻⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣼⠋⠀⠀⢀⣤⣤⣤⣤⣤⣤⣤⣿⣦⣤⣤⣤⣤⣤⣤⣴⣿⣤⣤⣤⣤⣤⣤⣤⡀⠀⠀⠙⣧⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣸⠏⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⢠⣴⠞⠛⠛⠻⢦⡄⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠸⣇⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⡟⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⣿⣿⢶⣄⣠⡶⣦⣿⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⢻⡄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣾⠁⠀⠀⠀⠀⠘⣇⠀⠀⠀⠀⠀⠀⠀⢻⣿⠶⠟⠻⠶⢿⡿⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠈⣿⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢰⡏⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⢾⣄⣹⣦⣀⣀⣴⢟⣠⡶⠀⠀⠀⠀⠀⠀⣼⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠈⠛⠿⣭⣭⡿⠛⠁⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠘⣧⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⢿⡀⠀⠀⠀⠀⠀⠀⣀⡴⠞⠋⠙⠳⢦⣀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⢰⡏⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⢿⣄⣀⠀⠀⢀⣤⣼⣧⣤⣤⣤⣤⣤⣿⣭⣤⣤⣤⣤⣤⣤⣭⣿⣤⣤⣤⣤⣤⣼⣿⣤⣄⠀⠀⣀⣠⡾⠁⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⠛⠻⢧⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠤⠼⠟⠛⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣷⣶⣶⣶⣶⣶⣶⣿⣷⣶⣿⣿⣾⣿⣶⣶⣿⣿⣷⣿⣿⣿⣿⣿⣿⣾⣿⣿⣿⣿⣷⣷⣿⣷⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶
               RANSOMWARE SIMULATOR
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣷⣶⣿⣿

"""


class FileEncryptor:
    def __init__(self, key_file, log_file=None, debug=False):
        """Initialize the FileEncryptor with the encryption key and set up logging"""
        self.key = self.load_key(key_file)
        self.f = Fernet(self.key)
        self.setup_logging(log_file, debug)

    def load_key(self, key_file):
        """Load encryption key from a file"""
        with open(key_file, 'rb') as file:
            return file.read()

    def setup_logging(self, log_file=None, debug=False):
        """Set up logging"""
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.DEBUG if debug else logging.INFO)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%dT%H:%M:%S%z')
        if log_file:
            file_handler = logging.FileHandler(log_file)
            file_handler.setFormatter(formatter)
            self.logger.addHandler(file_handler)
        else:
            console_handler = logging.StreamHandler()
            console_handler.setFormatter(formatter)
            self.logger.addHandler(console_handler)

    def encrypt_file(self, file_path):
        """Encrypt a file with the given key"""
        if file_path.endswith('.encrypted'):
            self.logger.error(f"File '{file_path}' is already encrypted.")
            return
        try:
            with open(file_path, 'rb') as file:
                data = file.read()
            encrypted_data = self.f.encrypt(data)
            with open(file_path + '.encrypted', 'wb') as encrypted_file:
                encrypted_file.write(encrypted_data)
            if self.logger.isEnabledFor(logging.DEBUG):
                self.logger.debug(f"Encrypted file: {file_path}")
        except Exception as e:
            self.logger.error(f"Failed to encrypt file: {file_path}. Error: {str(e)}")
            return False
        return True

    def decrypt_file(self, encrypted_file_path):
        """Decrypt an encrypted file with the given key"""
        if not encrypted_file_path.endswith('.encrypted'):
            self.logger.error(f"File '{encrypted_file_path}' is already decrypted.")
            return
        try:
            with open(encrypted_file_path, 'rb') as encrypted_file:
                encrypted_data = encrypted_file.read()
            decrypted_data = self.f.decrypt(encrypted_data)
            with open(encrypted_file_path[:-len('.encrypted')], 'wb') as decrypted_file:
                decrypted_file.write(decrypted_data)
            if self.logger.isEnabledFor(logging.DEBUG):
                self.logger.debug(f"Decrypted file: {encrypted_file_path}")
        except Exception as e:
            self.logger.error(f"Failed to decrypt file: {encrypted_file_path}. Error: {str(e)}")
            return False
        return True

    def ascii_art(self):
        print(__ascii_art__)

    def process_directory(self, directory, encrypt=True, delete_original=False):
        """Process files in a directory recursively"""
        for root, dirs, files in os.walk(directory):
            for file in files:
                file_path = os.path.join(root, file)
                success = False
                if encrypt:
                    success = self.encrypt_file(file_path)
                else:
                    success = self.decrypt_file(file_path)
                if delete_original and success:
                    os.remove(file_path)
        if encrypt:
            self.ascii_art()
        self.logger.info("Operation completed successfully.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Encrypt or decrypt files in a directory recursively using a given key")
    parser.add_argument("action", choices=["encrypt", "decrypt"], help="Specify whether to encrypt or decrypt files")
    parser.add_argument("key_file", help="Path to the file containing the encryption key")
    parser.add_argument("directory", help="Path to the directory to process")
    parser.add_argument("--delete-original", action="store_true", help="Delete original files after encryption/decryption", required=True)
    parser.add_argument("--log-file", help="Path to the log file")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode to print detailed information")
    args = parser.parse_args()
    
    file_encryptor = FileEncryptor(args.key_file, args.log_file, debug=args.debug)
    file_encryptor.process_directory(args.directory, encrypt=args.action == "encrypt", delete_original=args.delete_original)
