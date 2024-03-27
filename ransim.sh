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

echo "Install python3-full..."
apt-get install -y python3-full &> /dev/null
echo "Create scripts repository..."
mkdir -p $RBK_PATH
echo "Create python venv..."
python3 -m venv $RBK_PATH/venv &> /dev/null
echo "Install cryptography lib..."
$RBK_PATH/venv/bin/python -m pip install cryptography &> /dev/null
echo "Download crypto script..."
wget -O $RBK_PATH/encrypt_file.py $URL/encrypt_file.py &> /dev/null
wget -O $RBK_PATH/key $URL/key &> /dev/null
chmod 754 $RBK_PATH/encrypt_file.py &> /dev/null
echo "Operation completed successfully."
