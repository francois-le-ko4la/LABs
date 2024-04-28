#!/bin/sh
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
# - Linux platform: Debian 7+, Ubuntu 20.04+, RHEL 8+ or CentOS 9+
# - python 3.6+
#
# USAGE:
#  curl https://raw.githubusercontent.com/francois-le-ko4la/LABs/main/ransim.sh | sudo sh
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

RBK_PATH="/opt/rubrik/scripts"
URL="https://raw.githubusercontent.com/francois-le-ko4la/LABs/main"
INST_PYTHON=0
DOWN_CRYPTO=""

# Logging function
log() {
    echo "$(date --iso-8601=seconds) - RANSIM - $1"
}

# Check the user
if [ "$(id -u)" -ne 0 ]; then
    log "Please run this script as root or using sudo!"
    exit 1
fi

# Detect the OS and Version
if [ "$(uname)" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if { [ "$ID" = "ubuntu" ] && [ "${VERSION_ID%.*}" -ge 20 ]; } || \
           { [ "$ID" = "debian" ] && [ "$VERSION_ID" -ge 11 ]; }; then
            log "Debian/Ubuntu detected."
            INST_PYTHON=1
        elif { [ "$ID" = "centos" ] && [ "$VERSION_ID" -ge 9 ]; } || \
             { [ "$ID" = "rhel" ] && [ "$VERSION_ID" -ge 8 ]; }; then
            log "CENTOS/RHEL detected."
            INST_PYTHON=2
        elif [ "$ID" = "centos" ] && [ "$VERSION_ID" -ge 7 ]; then
            log "CENTOS detected. Downgrade cryptography."
            INST_PYTHON=2
            DOWN_CRYPTO="==36.0.2"
        else
            log "Unsupported platform. Exiting..."
            exit 1
        fi
    else
        log "Unable to detect the operating system."
        exit 1
    fi
else
    log "This script only works on Linux systems."
    exit 1
fi

log "Installing python3-full..."
if [ "$INST_PYTHON" -eq 1 ]; then
    apt-get -yq install python3-full > /dev/null 2>&1 || { log "Installation of python3-full failed."; exit 1; }
elif [ "$INST_PYTHON" -eq 2 ]; then
    yum install -y python3 > /dev/null 2>&1 || { log "Installation of python3 failed."; exit 1; }
fi

log "Creating scripts repository..."
mkdir -p $RBK_PATH
log "Creating python venv..."
python3 -m venv $RBK_PATH/venv > /dev/null 2>&1 || { log "Creation of python venv failed."; exit 1; }
log "Installing cryptography lib..."
$RBK_PATH/venv/bin/python -m pip install --upgrade pip > /dev/null 2>&1
$RBK_PATH/venv/bin/python -m pip install cryptography$DOWN_CRYPTO > /dev/null 2>&1 || { log "Installation of cryptography library failed."; exit 1; }
log "Downloading crypto script..."
wget -q -O $RBK_PATH/encrypt_file.py $URL/encrypt_file.py > /dev/null 2>&1 || { log "Download of encrypt_file.py failed."; exit 1; }
wget -q -O $RBK_PATH/key $URL/key > /dev/null 2>&1 || { log "Download of key failed."; exit 1; }
chmod 754 $RBK_PATH/encrypt_file.py > /dev/null 2>&1
log "Operation completed successfully."
