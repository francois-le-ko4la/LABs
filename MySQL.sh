#!/bin/sh
#
# DESCRIPTION:
# This script sets up a demo MySQL database with a service account
# and a dump script.
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
# - ubuntu 20.04+
#
# SETUP:
#  curl https://raw.githubusercontent.com/francois-le-ko4la/LABs/main/MySQL.sh | sudo sh
#
# After running the script, you'll have:
# - A MySQL database named "employees"
# - A backup account rubrik_svc/Rubrik@123!
# - An example dump script
#

SCRIPT_DIR="/opt/rubrik/scripts"
SCRIPT_PATH="/opt/rubrik/scripts/dump_mysql.sh"
SLAMV_PATH="/mnt/rubrik_slamv"
MYSQL_RUBRIK_USER="rubrik_svc"
MYSQL_RUBRIK_PASS="Rubrik@123!"
ERROR="ERROR"
INFO="INFO"

# Logging function
log() {
    local SEV="$1"
    local MSG="$2"
    echo "$(date --iso-8601=seconds) - MySQL - $SEV - $MSG"
}

# Check the user
if [ "$(id -u)" -ne 0 ]; then
    log "$ERROR" "Please run this script as root or using sudo!"
    exit 1
fi

# Check if the platform is Linux
if [ "$(uname)" != "Linux" ]; then
    log "$ERROR" "This script only works on Linux systems."
    exit 1
fi

# Check if the platform is Ubuntu 20.04 or newer
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ] && [ "${VERSION_ID%.*}" -ge 20 ]; then
        log "$INFO" "Ubuntu 20.04 or newer detected."
    else
        log "$ERROR" "Unsupported Ubuntu version. Exiting..."
        exit 1
    fi
else
    log "$ERROR" "Unable to detect the operating system."
    exit 1
fi

if dpkg -l | egrep '^ii.*mariadb-server'; then
    log "$ERROR" "MariaDB is installed. Exiting."
    exit 1
fi

log "$INFO" "Install MySQL package..."
apt install -y git wget nfs-common mysql-server > /dev/null 2>&1 || { log "$ERROR" "Failed to install MySQL package. Exiting."; exit 1; }

log "$INFO" "Enable/start service..."
systemctl enable mysql.service > /dev/null 2>&1 || { log "$ERROR" "Failed to enable MySQL service. Exiting."; exit 1; }
systemctl start mysql.service > /dev/null 2>&1 || { log "$ERROR" "Failed to start MySQL service. Exiting."; exit 1; }

log "$INFO" "Download test database..."
git clone https://github.com/datacharmer/test_db.git > /dev/null 2>&1 || { log "$ERROR" "Failed to download test database. Exiting."; exit 1; }

log "$INFO" "Import test database..."
cd test_db
mysql < employees.sql > /dev/null 2>&1 || { log "$ERROR" "Failed to import test database. Exiting."; exit 1; }

log "$INFO" "Define backup account..."
cat << EOF > adduser.sql
CREATE USER '$MYSQL_RUBRIK_USER'@'localhost' IDENTIFIED BY '$MYSQL_RUBRIK_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_RUBRIK_USER'@'localhost' WITH GRANT OPTION;
EOF

sudo mysql < adduser.sql 2>&1 || { log "$ERROR" "Failed to import test database. Exiting."; exit 1; }

log "$INFO" "Add dump script"
mkdir -p $SCRIPT_DIR || { log "$ERROR" "Failed to create scripts directory. Exiting."; exit 1; }
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


DOTD=\$(date +"%Y_%m_%d_%H_%M_%S")
USERNAME="$MYSQL_RUBRIK_USER"
PASSWORD="$MYSQL_RUBRIK_PASS"
DB_NAME="employees"
BACKUP_DIR="$SLAMV_PATH"

ERROR="ERROR"
INFO="INFO"

# Logging function
log() {
    local SEV="\$1"
    local MSG="\$2"
    echo "\$(date --iso-8601=seconds) - MySQLDump - \$SEV - \$MSG"
}

log "\$INFO" "Starting MySQL dump..."

if mysqldump -u "\$USERNAME" --password="\$PASSWORD" "\$DB_NAME" > "\$BACKUP_DIR/\$DB_NAME-\$DOTD.sql" > /dev/null 2>&1; then
    log "\$INFO" "MySQL dump finished successfully!"
else
    log "\$ERROR" "MySQL dump failed, check logs for details..."
    exit 1
fi

log "\$INFO" "MySQL dump cleanup in progress..."
# Supprime les fichiers plus anciens de 3 jours dans le répertoire de sauvegarde
find "\$BACKUP_DIR" -type f -name "\$DB_NAME-*.sql" -mtime +3 -exec rm {} \;
log "\$INFO" "MySQL dump cleanup finished successfully!"

exit 0
EOF

chmod 764 $SCRIPT_PATH
log "$INFO" "Operation completed successfully."
