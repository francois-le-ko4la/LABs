#/bin/sh
# little script to deploy a test db

SCRIPT_PATH=/scripts/
mkdir $SCRIPT_PATH
cd $SCRIPT_PATH
apt-get install mysql-server unzip
wget https://github.com/datacharmer/test_db/archive/refs/heads/master.zip
unzip master.zip
cd test_db-master/
mysql -t < employees.sql
