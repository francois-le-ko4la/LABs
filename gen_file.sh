#!/bin/bash

DEST="/home/shares"

wget https://github.com/francois-le-ko4la/LABs/blob/master/lorem.txt
mkdir -p $DEST
for i in {1..4096}; do cp lorem.txt $DEST/lorem$i.txt; done
 
