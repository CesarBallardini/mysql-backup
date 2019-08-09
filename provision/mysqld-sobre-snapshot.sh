#!/usr/bin/env bash

SNAPSHOT_NAME=snap_backup
MYSQL_ROOT_PASSWORD=perico

https://www.lullabot.com/articles/mysql-backups-using-lvm-snapshots

TCP port diferente
MYSQL_PORT=$( mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e "select @@port;" 2> /dev/null )
# 3306 

mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e 'SHOW VARIABLES LIKE "PORT";' 2> /dev/null
#
# port	3306


MySQL socket diferente
MYSQL_SOCKET=$( mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e 'SHOW VARIABLES LIKE "socket";' 2> /dev/null | cut -f2 )
#
# socket	/var/run/mysqld/mysqld.sock

El  --innodb-log-file-size must be identical to the primary MySQL instance,
INNODB_SIZE=$( mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e 'SHOW VARIABLES LIKE "%innodb_log_file_size%";' 2> /dev/null  | cut -f2 )
innodb_log_file_size	50331648

sudo mysqld_safe \
	--no-defaults \
	--port=$[ $MYSQL_PORT + 1 ] \
	--socket=$(dirname ${MYSQL_SOCKET} )/mysqld-snapshot.sock \
	--datadir=/mnt/"${SNAPSHOT_NAME}/data"  \
	--innodb-log-file-size=${INNODB_SIZE} &

sudo mysqldump --user=root --password="${MYSQL_ROOT_PASSWORD}" \
       	--all-databases \
	-S $(dirname ${MYSQL_SOCKET} )/mysqld-snapshot.sock \
  | gzip > /tmp/backup.sql.gz


zless /tmp/backup.sql.gz

sudo mysqladmin --user=root --password="${MYSQL_ROOT_PASSWORD}" -S $(dirname ${MYSQL_SOCKET} )/mysqld-snapshot.sock shutdown

# Remove Snapshot
sudo umount "/mnt/${SNAPSHOT_NAME}" && sudo rm -rf "/mnt/${SNAPSHOT_NAME}" && sudo dmsetup remove "/dev/vg_mysql_data/${SNAPSHOT_NAME}" && sudo lvremove --force "/dev/vg_mysql_data/${SNAPSHOT_NAME}"

