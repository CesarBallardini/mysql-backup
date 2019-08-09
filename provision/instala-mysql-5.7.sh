#!/usr/bin/env bash
#set -e
#set -x

MYSQL_ROOT_PASSWORD=perico
# Buscar mysql-apt-config en https://dev.mysql.com/downloads/repo/apt/
PKG_NAME=mysql-apt-config_0.8.13-1_all.deb
PKG_MD5SUM=0212f2f1aaa46ccae8bc7a65322be22e


sudo apt -q update
sudo apt -y upgrade

elimina_mysql() {

  sudo apt purge -y --ignore-missing mysql-server mysql-client mysql-common mysql-server-core-5.7 mysql-client-core-5.7 mysql-apt-config  mysql-community-server
  sudo apt purge -y --ignore-missing mysql-client mysql-common mysql-community-client mysql-community-server  mysql-apt-config
# 
# This operation will remove the data directory at '/var/lib/mysql' that stores all the databases, tables and related meta-data. Additionally, any import or export 
# files stored at '/var/lib/mysql-files' will be removed along with directory. Finally, any files in '/var/lib/mysql-keyring' will be deleted. It is highly
# recommended to take data backup before removing the data directories. 
#
  sudo rm -rf /var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring
  sudo rm -rf /mnt/mysql/data /mnt/mysql/mysql-files /mnt/mysql/mysql-keyring
  sudo apt autoremove -y
}


#elimina_mysql

sudo apt install -y rsync

# para obtener las respuestas de debconf installer
sudo apt install -y debconf-utils

sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/repo-codename select buster'
sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/repo-distro select debian'
sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/repo-url string http://repo.mysql.com/apt/'
sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-preview select '
sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-product select	Ok'
sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-server select	mysql-5.7'
sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-tools select '
sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/unsupported-platform select abort'


sudo debconf-set-selections <<< 'mysql-apt-config	mysql-apt-config/tools-component	string	'
sudo debconf-set-selections <<< 'mysql-apt-config	mysql-apt-config/preview-component	string	'
sudo debconf-set-selections <<< 'mysql-apt-config	mysql-apt-config/dmr-warning	note	'
sudo debconf-set-selections <<< 'mysql-community-server	mysql-community-server/data-dir	note	'



pushd /tmp
[ -f "${PKG_NAME}" ] || wget http://repo.mysql.com/"${PKG_NAME}"
md5sum --status --check <<<"${PKG_MD5SUM} *${PKG_NAME}"
ret=$?
popd
[ $ret -eq 0 ] || exit 1


sudo DEBIAN_FRONTEND=noninteractive dpkg -i "${PKG_NAME}"

sudo apt-get -q update


sudo debconf-set-selections <<< "mysql-community-server	mysql-community-server/root-pass	password ${MYSQL_ROOT_PASSWORD}"
sudo debconf-set-selections <<< "mysql-community-server	mysql-community-server/re-root-pass	password ${MYSQL_ROOT_PASSWORD}"


sudo apt-get install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" mysql-server

##
# hay tres directorios donde MySQL instala archivos: 
# /var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring
#
# drwxr-x--- 6 mysql mysql 4096 Aug  4 03:33 /var/lib/mysql
# drwxrwx--- 2 mysql mysql 4096 Aug  4 03:32 /var/lib/mysql-files
# drwxr-x--- 2 mysql mysql 4096 Aug  4 03:32 /var/lib/mysql-keyring
#

# mysql --user=root --password="${MYSQL_ROOT_PASSWORD}"  -e "SELECT @@GLOBAL.keyring_encrypted_file_data;" 
# mysql: [Warning] Using a password on the command line interface can be insecure.
# ERROR 1193 (HY000) at line 1: Unknown system variable 'keyring_encrypted_file_data'
# 
# mysql --user=root --password="${MYSQL_ROOT_PASSWORD}"  -e "SELECT @@keyring_encrypted_file_data;" 
# mysql: [Warning] Using a password on the command line interface can be insecure.
# ERROR 1193 (HY000) at line 1: Unknown system variable 'keyring_encrypted_file_data'
# 
# mysql --user=root --password="${MYSQL_ROOT_PASSWORD}"  -e "SELECT keyring_encrypted_file_data;" 
# mysql: [Warning] Using a password on the command line interface can be insecure.
# ERROR 1054 (42S22) at line 1: Unknown column 'keyring_encrypted_file_data' in 'field list'


mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e 'SHOW VARIABLES LIKE "secure_file_priv";' 2> /dev/null
# muestra:
# secure_file_priv	/var/lib/mysql-files/


mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e "select @@datadir;" 2> /dev/null
# muestra:
# /var/lib/mysql/

# change datadir

OLD_DATA_DIR=$( mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e "select @@datadir;" 2> /dev/null )
NEW_DATA_DIR=/mnt/mysql/data

##
# FIXME: uso /mnt/mysql en forma explicita -> usar variables!!

sudo mkdir -p "${NEW_DATA_DIR}" /mnt/mysql/mysql-files  /mnt/mysql/mysql-keyring
sudo chmod 750 /mnt/mysql/mysql-keyring "${NEW_DATA_DIR}"
sudo chmod 770 /mnt/mysql/mysql-files
sudo chown -R mysql:mysql "${NEW_DATA_DIR}" /mnt/mysql/mysql-files  /mnt/mysql/mysql-keyring


sudo systemctl stop mysql
sudo systemctl is-active mysql || true

# cp -R -p /var/lib/mysql/* /mnt/mysql/data
sudo rsync -Pa  "${OLD_DATA_DIR}" "${NEW_DATA_DIR}"
sudo rsync -Pa  /var/lib/mysql-files /mnt/mysql/
sudo rsync -Pa  /var/lib/mysql-keyring /mnt/mysql/

# https://dev.mysql.com/doc/refman/5.7/en/keyring-system-variables.html#sysvar_keyring_encrypted_file_data -> keyring_encrypted_file_data (system variable)



#$ grep -R socket /etc/mysql/*
#/etc/mysql/my.cnf.fallback:# Remember to edit /etc/mysql/debian.cnf when changing the socket location.
#/etc/mysql/mysql.conf.d/mysqld.cnf:socket		= /var/run/mysqld/mysqld.sock
#
#
#$ grep -R datadir  /etc/mysql/*
#/etc/mysql/mysql.conf.d/mysqld.cnf:datadir		= /var/lib/mysql

#RedHat: Add the SELinux security context to /mnt/mysql-data before restarting MariaDB.
#
#sudo semanage fcontext -a -t mysqld_db_t "/mnt/mysql-data(/.*)?"
#sudo restorecon -R /mnt/mysql-data
#

cat - | sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf > /dev/null <<!EOF
[mysqld]
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
secure_file_priv="/mnt/mysql/mysql-files"
datadir=/mnt/mysql/data
#datadir                = /var/lib/mysql
log-error       = /var/log/mysql/error.log
# By default we only accept connections from localhost
bind-address    = 127.0.0.1
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0


[client]
port=3306
!EOF


sudo systemctl start mysql
sudo systemctl is-active mysql


# confirmar datadir actual:
mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e "select @@datadir;" 2> /dev/null
mysql --user=root --password="${MYSQL_ROOT_PASSWORD}" -sss -e 'SHOW VARIABLES LIKE "secure_file_priv";' 2> /dev/null



## creo una base y compruebo que lo hace en el nuevo datadir
#mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE pruebas;"
#sudo ls -l "${NEW_DATA_DIR}" | grep pruebas


# mysql -u root -password -e "use mysql; UPDATE user SET authentication_string=PASSWORD('${MYSQL_ROOT_PASSWORD}') WHERE User='root'; flush privileges;"
