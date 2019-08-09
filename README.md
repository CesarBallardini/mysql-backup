# README

# Objetivo


La idea general es que el directorio `/var/lib/mysql/` donde se guardan los datos del motor, reside en un filesystem que está creado sobre una unidad lógica de LVM.

Como LVM permite hacer snapshots, que son casi instantáneos, si lo haces desde dentro de una transaccion de la base como en 

https://github.com/CesarBallardini/mysql-backup/blob/master/provision/respalda-mysql.sh#L20

se ve que el formato del código central es:

```bash
mysql \
  --user=root \
  --password="${MYSQL_ROOT_PASSWORD}" \
  --batch \
  --silent \
  --execute="
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS\G;
system sudo lvcreate --size "${SNAPSHOT_SIZE}" --snapshot --name "${SNAPSHOT_NAME}" "${DATA_PART}";
UNLOCK TABLES;
"
```

O sea, entre el flush + read lock y el unlock tables se hace el snapshot, despues de hacer un flush de todas las escrituras.  Como es tan rápido, el tiempo que la base no responde a las escrituras es solamente lo que tarda en hacer el flush de las escrituras pendientes.  Todas las lecturas se siguen haciendo sin percances durante esos segundos.

El snapshot después es un `/dev/DISPOSITIVO` asi que lo podes montar con mount y usarlo.  Se puede usar básicamente para dos cosas: 1) es copiarlo a otro nodo para respaldarlo o 2) para levantar otro daemon de MySQL que escucha en otro puerto y es el que usás para realizar el backup, sin molestar al daemon original que hace rato está atendiendo de nuevo las lecturas y escrituras. Hay un 3) que combina los anteriores: copias el directorio a otro nodo, y en ese otro nodo levantas un daemon MySQL con lo cual ni siquiera competis por el filesystem a la hora de acceder para hacer el backup.

Cuando el backup está tomado, sencillamente borras el snapshot y desaparece sin dejar molestias residuales.


# Pasos a seguir

Uso Debian 10 (Buster) para instalar MySQL 5.7

El sistema de archivos de la base de datos esta montado sobre un dispositivo LVM
lo cual nos permite hacer snapshots.

La estrategia es la siguiente:

1. Instalamos un Debian 10 sobre dispositivos LVM

2. El directorio `/var/lib/mysql/` reside en una unidad lógica separada de `/`

3. Instalamos MySQL 5.7

4. Cargamos una base con tablas y registros

5. Realizamos el backup de la unidad con los archivos de MySQL mediante un snapshot

6. Montamos el snapshot y copiamos a otro nodo

7. Montamos el snapshot y levantamos otro mysqld en un puerto diferente; usamos mysqldump desde
   ese daemon para hacer el backup.

8. Modificamos los registros, tablas y bases

9. Restauramos desde el snapshot

10. Eliminamos el snapshot.


# Creación del entorno de trabajo


* levantar VM

```bash
time vagrant up
```

* ingresar a la VM

```bash
vagrant ssh
```


* crear partición LVM para `/mnt/mysql`

```bash
/vagrant/provision/format-extra-disk.sh
```

* instalar MySQL 5.7

```bash
/vagrant/provision/instala-mysql-5.7.sh
```

* respalda MySQL en `/tmp/backup`

```bash
/vagrant/provision/respalda-mysql.sh
```

* levanta un `mysqld` sobre el snapshot para correr el `mysqldump`

```bash
/vagrant/provision/mysqld-sobre-snapshot.sh
```

# TODO

* Modificamos los registros, tablas y bases

* Restauramos desde el snapshot

* Eliminamos el snapshot.


# Referencias


* https://www.lullabot.com/articles/mysql-backups-using-lvm-snapshots

* Las variantes de `Vagrantfile.[123]` se refieren a capacidades incrementales, a saber:
  1. `Vagrantfile.1` descarga box y crea una VM con Debian Buster
  2. `Vagrantfile.2` agrega un segundo disco en un subdirectorio ./tmp/
  3. `Vagrantfile.3` agrega un segundo disco en el mismo directorio que usa VB para la vm
  4. `Vagrantfile` es el definitivo, agrega un sync folder `/vagrant/`


