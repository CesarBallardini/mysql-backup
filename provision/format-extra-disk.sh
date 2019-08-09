#!/usr/bin/env bash

set -e
set -x

sudo apt install -y lvm2

sudo lvmdiskscan

#vagrant@buster:~$ sudo lvmdiskscan
#  /dev/sda1 [      18.80 GiB] 
#  /dev/sda5 [    1021.00 MiB] 
#  /dev/sdb  [     500.00 MiB] 
#  1 disk
#  2 partitions
#  0 LVM physical volume whole disks
#  0 LVM physical volumes
#

# inicializa los volumenes para LVM
sudo pvcreate /dev/sdb
#   Physical volume "/dev/sdb" successfully created.


# ver el physical volume:
sudo pvdisplay

#vagrant@buster:~$ sudo pvdisplay
#  "/dev/sdb" is a new physical volume of "500.00 MiB"
#  --- NEW Physical volume ---
#  PV Name               /dev/sdb
#  VG Name
#  PV Size               500.00 MiB
#  Allocatable           NO
#  PE Size               0
#  Total PE              0
#  Free PE               0
#  Allocated PE          0
#  PV UUID               irRwYu-uXj1-Upwj-f7yY-u1sk-sndd-ArNd9G
#
#

# create a volume group:
sudo vgcreate vg_mysql_data /dev/sdb
#  Volume group "vg_mysql_data" successfully created

# ver volume group:
sudo vgdisplay

#vagrant@buster:~$ sudo vgdisplay
#  --- Volume group ---
#  VG Name               vg_mysql_data
#  System ID
#  Format                lvm2
#  Metadata Areas        1
#  Metadata Sequence No  1
#  VG Access             read/write
#  VG Status             resizable
#  MAX LV                0
#  Cur LV                0
#  Open LV               0
#  Max PV                0
#  Cur PV                1
#  Act PV                1
#  VG Size               496.00 MiB
#  PE Size               4.00 MiB
#  Total PE              124
#  Alloc PE / Size       0 / 0
#  Free  PE / Size       124 / 496.00 MiB
#  VG UUID               y4beCt-7CV2-mQXP-s32Y-sQDN-opMg-uRDCR6
#


# create a logical volume:
sudo lvcreate -L 300M -n lv_var_lib_mysql vg_mysql_data

#  Logical volume "lv_var_lib_mysql" created.

# A proposito dejamos espacio libre para crear los snapshots en el futuro
# ver cuanto espacio libre quedo  en el volume group:
sudo vgs -o +lv_size,lv_name

#vagrant@buster:~$ sudo vgs -o +lv_size,lv_name
#  VG            #PV #LV #SN Attr   VSize   VFree   LSize   LV              
#  vg_mysql_data   1   1   0 wz--n- 496.00m 196.00m 300.00m lv_var_lib_mysql
#

# ver el logical volume:
sudo lvdisplay

#vagrant@buster:~$ sudo lvdisplay
#  --- Logical volume ---
#  LV Path                /dev/vg_mysql_data/lv_var_lib_mysql
#  LV Name                lv_var_lib_mysql
#  VG Name                vg_mysql_data
#  LV UUID                fYZq5K-XEn0-N9Yy-FKy0-UafG-eRxP-IvEv0H
#  LV Write Access        read/write
#  LV Creation host, time buster, 2019-08-02 19:01:18 +0000
#  LV Status              available
#  # open                 0
#  LV Size                300.00 MiB
#  Current LE             75
#  Segments               1
#  Allocation             inherit
#  Read ahead sectors     auto
#  - currently set to     256
#  Block device           254:0
#   


# formateamos el logical volume
sudo mkfs.ext4 /dev/mapper/vg_mysql_data-lv_var_lib_mysql

#mke2fs 1.44.5 (15-Dec-2018)
#Creating filesystem with 307200 1k blocks and 76912 inodes
#Filesystem UUID: 63fd5c7d-a7cc-4f07-a2c9-2ef8fe987fd1
#Superblock backups stored on blocks: 
#	8193, 24577, 40961, 57345, 73729, 204801, 221185
#
#Allocating group tables: done                            
#Writing inode tables: done                            
#Creating journal (8192 blocks): done
#Writing superblocks and filesystem accounting information: done 
#


# https://xanmanning.co.uk/2017/05/29/best-practice-for-mounting-an-lvm-logical-volume-with-etc-fstab.html
sudo mkdir /mnt/mysql
sudo mount /dev/mapper/vg_mysql_data-lv_var_lib_mysql  /mnt/mysql/


cat - | sudo tee --append /etc/fstab > /dev/null <<!EOF
/dev/mapper/vg_mysql_data-lv_var_lib_mysql  /mnt/mysql/  ext4  defaults  0 0
!EOF

