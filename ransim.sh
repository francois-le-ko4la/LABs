#!/bin/sh
#
# goal:
# This script sets up a demo to demonstrate Rubrik Anomaly Detection/Threat Hunting
#
# usage:
#  sudo curl https://raw.githubusercontent.com/francois-le-ko4la/LABs/master/ransim.sh | sudo sh
#

RBK_PATH="/opt/rubrik/scripts"
URL="https://raw.githubusercontent.com/francois-le-ko4la/LABs/master"
INST_PYTHON=""

# Logging function
log() {
    echo "$(date --iso-8601=seconds) - RANSIM - $1"
}

# Detect the OS and Version
if [ "$(uname)" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if { [ "$ID" = "ubuntu" ] && [ "${VERSION_ID%.*}" -ge 20 ]; } || \
           { [ "$ID" = "debian" ] && [ "$VERSION_ID" -ge 11 ]; }; then
            log "Debian/Ubuntu detected. Installing python3-full..."
            INST_PYTHON="apt install -y python3-full 2>&1 /dev/null"
        elif { [ "$ID" = "centos" ] && [ "$VERSION_ID" -ge 9 ]; } || \
             { [ "$ID" = "rhel" ] && [ "$VERSION_ID" -ge 8 ]; }; then
            log "RHEL 8 or newer detected. Installing python3..."
            INST_PYTHON="yum install -y python3 2>&1 /dev/null"
        else
            log "Unsupported CENTOS/RHEL version. Exiting..."
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

log "Install python3-full..."
$INST_PYTHON
log "Create scripts repository..."
mkdir -p $RBK_PATH
log "Create python venv..."
python3 -m venv $RBK_PATH/venv > /dev/null 2>&1
log "Install cryptography lib..."
$RBK_PATH/venv/bin/python -m pip install cryptography > /dev/null 2>&1
log "Download crypto script..."
wget -q -O $RBK_PATH/encrypt_file.py $URL/encrypt_file.py > /dev/null 2>&1
wget -q -O $RBK_PATH/key $URL/key > /dev/null 2>&1
chmod 754 $RBK_PATH/encrypt_file.py > /dev/null 2>&1
log "Operation completed successfully."
