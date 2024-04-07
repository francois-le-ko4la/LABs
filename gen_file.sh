#!/bin/bash

DEST="/home/shares"

wget https://raw.githubusercontent.com/francois-le-ko4la/LABs/master/lorem.txt
mkdir -p $DEST
for i in {1..4096}; do cp lorem.txt $DEST/lorem$i.txt; done
 
