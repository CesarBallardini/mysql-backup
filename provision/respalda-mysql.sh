#!/usr/bin/env bash

MYSQL_ROOT_PASSWORD=perico
BACKUP_DIR=/tmp/backup
SNAPSHOT_SIZE=100M
SNAPSHOT_NAME=snap_backup


sudo mkdir -p "${BACKUP_DIR}"

DATA_DIR=$( mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e "select @@datadir;" 2> /dev/null )
DATA_PART=$( LANG=C df  --output=source  "${DATA_DIR}" | grep dev )


#LANG=C sudo vgdisplay vg_mysql_data | grep Free

mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" --batch --silent --execute="
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS\G;
system sudo lvcreate --size "${SNAPSHOT_SIZE}" --snapshot --name "${SNAPSHOT_NAME}" "${DATA_PART}";
UNLOCK TABLES;
" | sudo tee  "${BACKUP_DIR}/master_status"

# veo snapshot creado:
sudo lvdisplay "${DATA_PART}"

# Mount snapshot
sudo mkdir -p "/mnt/${SNAPSHOT_NAME}" && sudo mount "/dev/vg_mysql_data/${SNAPSHOT_NAME}"  "/mnt/${SNAPSHOT_NAME}"

# Backup Snapshot
sudo rsync -a --partial --delete --exclude=/*.info "/mnt/${SNAPSHOT_NAME}/" "${BACKUP_DIR}/"
# FIXME: que pasa con mysql-keyring y mysql-files ???


# Remove Snapshot
#sudo umount "/mnt/${SNAPSHOT_NAME}" && sudo rm -rf "/mnt/${SNAPSHOT_NAME}" && sudo dmsetup remove "/dev/vg_mysql_data/${SNAPSHOT_NAME}" && sudo lvremove --force "/dev/vg_mysql_data/${SNAPSHOT_NAME}"
