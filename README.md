# README

Uso Debian 10 (Buster) para instalar MySQL 5.7

El sistema de archivos de la base de datos esta montado sobre un dispositivo LVM
lo cual nos permite hacer snapshots.

La estrategia es la siguiente:

1. Instalamos un Debian 10 sobre dispositivos LVM

2. El directorio `/var/lib/mysql/` reside en una unidad logica separada de `/`

3. Instalamos MySQL 5.7

4. Cargamos una base con tablas y registros

5. Realizamos el backup de la unidad con los archivos de MySQL mediante un snapshot

6. Montamos el snapshot y copiamos a otro nodo

7. Montamos el snapshot y levantamos otro mysqld en un puerto diferente; usamos mysqldump desde
   ese daemon para hacer el backup.

8. Modificamos los registros, tablas y bases

9. Restauramos desde el snapshot

10. Eliminamos el snapshot.


# Creacion del entorno de trabajo

* levantar VM

```bash
time vagrant up
```

* ingresar a la VM

```bash
vagrant ssh
```


* crear particion LVM para `/mnt/mysql`

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
* levvanta un `mysqld` sobre el snapshot para correr el `mysqldump`

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
  4. `Vagrantfile' es el definitivo, agrega un sync folder `/vagrant/`


