#!/bin/sh
#
# goal:
# This script sets up a demo MySQL database with a service account
# and a dump script.
#
# usage:
#  sudo curl https://raw.githubusercontent.com/francois-le-ko4la/LABs/master/MySQL.sh | sudo sh
#
# linux tested:
# - ubuntu 20.04+
#
# After running the script, you'll have:
# - A MySQL database named "employees"
# - A backup account rubrik_svc/Rubrik@123!
# - An example dump script
#
# DISCLAIMER:
# This script should not be used in a production environment without
# appropriate evaluation and additional modifications.
# The author of this script cannot be held responsible for any
# potential damages or losses resulting from its use.
#

SCRIPT_DIR="/opt/rubrik/scripts"
SCRIPT_PATH="/opt/rubrik/scripts/dump_mysql.sh"
SLAMV_PATH="/mnt/rubrik_slamv"
MYSQL_RUBRIK_USER="rubrik_svc"
MYSQL_RUBRIK_PASS="Rubrik@123!"

echo "$(date --iso-8601=seconds) - MySQL: install MySQL package"
apt install git wget nfs-common mysql-server -y

echo "$(date --iso-8601=seconds) - MySQL: enable/start service"
systemctl enable mysql.service
systemctl start mysql.service

echo "$(date --iso-8601=seconds) - MySQL: download test database"
git clone https://github.com/datacharmer/test_db.git

echo "$(date --iso-8601=seconds) - MySQL: import test database"
cd test_db
mysql < employees.sql

echo "$(date --iso-8601=seconds) - MySQL: define backup account"
cat << EOF > adduser.sql
CREATE USER '$MYSQL_RUBRIK_USER'@'localhost' IDENTIFIED BY '$MYSQL_RUBRIK_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_RUBRIK_USER'@'localhost' WITH GRANT OPTION;
EOF

sudo mysql < adduser.sql


echo "$(date --iso-8601=seconds) - MySQL: Add dump script"

mkdir -p $SCRIPT_DIR
cat << EOF > $SCRIPT_PATH
#!/bin/sh

# DISCLAIMER:
# This script is provided as an example only and should not be used
# as is in a production environment without appropriate evaluation and
# additional modifications.
# The user is responsible for understanding and adapting this script according
# to their specific needs, taking into account security, performance, and
# reliability considerations.
# The author of this script cannot be held responsible for any potential damages or
# losses resulting from its use.

dotd=\$(date +"%Y_%m_%d")
user_name="$MYSQL_RUBRIK_USER"
password="$MYSQL_RUBRIK_PASS"
db_name="employees"
backup_dir="$SLAMV_PATH"

echo "\$(date --iso-8601=seconds) - Mysqldump database started"

# Exécute la commande mysqldump
if mysqldump -u "\$user_name" --password="\$password" "\$db_name" > "\$backup_dir/\$db_name-\$dotd.sql"; then
    echo "\$(date --iso-8601=seconds) - Mysqldump database finished successfully"
else
    echo "\$(date --iso-8601=seconds) - Mysqldump failed, check logs for details"
    exit 1
fi


echo "\$(date --iso-8601=seconds) - Mysql dump cleanup"
# Supprime les fichiers plus anciens de 3 jours dans le répertoire de sauvegarde
find "\$backup_dir" -type f -name "\$db_name-*.sql" -mtime +3 -exec rm {} \;

exit 0
EOF

chmod 764 $SCRIPT_PATH
