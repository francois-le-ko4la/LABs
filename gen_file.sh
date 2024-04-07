#!/bin/sh

# Objective:
# Create multiple "lorem ipsum file" to encrypt.
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
#
# SETUP:
# sudo curl https://raw.githubusercontent.com/francois-le-ko4la/LABs/main/gen_file.sh | sudo sh
#

# Logging function
log() {
    echo "$(date --iso-8601=seconds) - GEN_FILE - $1"
}

DEST="/home/shares"
NUM_FILES=4096

log "Downloading lorem.txt..."
wget https://raw.githubusercontent.com/francois-le-ko4la/LABs/main/lorem.txt || { log "Failed to download lorem.txt. Exiting."; exit 1; }

mkdir -p "$DEST"
for i in $(seq 1 "$NUM_FILES"); do
    cp lorem.txt "$DEST/lorem$i.txt" || { log "Failed to copy lorem.txt to $DEST/lorem$i.txt. Exiting."; exit 1; }
done

log "File copy completed successfully."
