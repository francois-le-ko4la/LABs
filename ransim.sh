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

apt install -y python3-full
mkdir -p $RBK_PATH
python3 -m venv $RBK_PATH/venv
$RBK_PATH/venv/bin/python -m pip install cryptography
wget -O $RBK_PATH/encrypt_file.py $URL/encrypt_file.py
wget -O $RBK_PATH/key $URL/key
chmod 754 $RBK_PATH/encrypt_file.py
