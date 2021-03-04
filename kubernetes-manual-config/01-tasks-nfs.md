# NFS configuration

To configure NFS, identify the data disk from the storage structure:

```console
[adminUsername@nfs ~]$ sudo lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda       8:0    0   50G  0 disk 
└─sda1    8:1    0   50G  0 part /mnt/resource
sdb       8:16   0   30G  0 disk 
├─sdb1    8:17   0  500M  0 part /boot
├─sdb2    8:18   0   29G  0 part /
├─sdb14   8:30   0    4M  0 part 
└─sdb15   8:31   0  495M  0 part /boot/efi
sr0      11:0    1  628K  0 rom  
```
The intention is to create a VG (volume group) and a LG (logical volume) in case we need to increase storage in the future by making use of ```pvcreate``` and ```vgcreate```.

**Issue: we cannot use directly neither the main volume sdb nor the partitions!**
```console
[adminUsername@nfs ~]$ sudo pvcreate /dev/sda
  Cannot use /dev/sda: device is partitioned
[adminUsername@nfs ~]$ sudo pvcreate /dev/sda1
  Can't open /dev/sda1 exclusively.  Mounted filesystem?
  Can't open /dev/sda1 exclusively.  Mounted filesystem?
```

Check if volume is mounted: seems taht /dev/sda1 is mounted
```console
[adminUsername@nfs ~]$ df -hP
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        1,7G     0  1,7G   0% /dev
tmpfs           1,7G     0  1,7G   0% /dev/shm
tmpfs           1,7G   17M  1,7G   1% /run
tmpfs           1,7G     0  1,7G   0% /sys/fs/cgroup
/dev/sdb2        30G  3,6G   26G  13% /
/dev/sdb1       496M  327M  170M  66% /boot
/dev/sdb15      495M  7,3M  488M   2% /boot/efi
/dev/sda1        49G   53M   47G   1% /mnt/resource
```
Double checking that, indeed, it is mounted:
```console
[adminUsername@nfs ~]$ fuser -m -v /dev/sda1
                     USER        PID ACCESS COMMAND
/dev/sda1:           root     kernel mount /mnt/resource
```
**Solution: unmount first**
```console
[adminUsername@nfs ~]$ sudo umount /dev/sda1
```
This time, we successfully to create the VG:
```console
[adminUsername@nfs ~]$ sudo pvcreate /dev/sda1
WARNING: ext4 signature detected on /dev/sda1 at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/sda1.
  Physical volume "/dev/sda1" successfully created.
[adminUsername@nfs ~]$ sudo vgcreate data_vg /dev/sda1
  Volume group "data_vg" successfully created
[adminUsername@nfs ~]$ sudo lvcreate -l+2559 -n nfs_lv /dev/data_vg
  Logical volume "nfs_lv" created.
```

Now that the logical volume has been created, let's proceed to create the XFS filesystem type: 
```console
[adminUsername@nfs ~]$ sudo mkfs.xfs /dev/data_vg/nfs_lv 
meta-data=/dev/data_vg/nfs_lv    isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=4096  attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
Discarding blocks...Done.
```

**Issue: when trying to add a mount point to the logical volume, permission can be denied**
```console
[adminUsername@nfs ~]$ sudo echo "/dev/data_vg/nfs_lv        /srv/nfs                xfs     defaults        0 0" >> /etc/fstab
-bash: /etc/fstab: Permission denied
```
This is because, even though we are executing the command as ***sudo***, it's trying to open the file with your ***adminUsername*** permissions not those of the process you're running under sudo

**Solution: using sudo tee append**
```console
[adminUsername@nfs ~]$ sudo echo "/dev/data_vg/nfs_lv        /srv/nfs                xfs     defaults        0 0" | sudo tee -a /etc/fstab
```
There are other solutions, like triggering bash command:
```bash
sudo sh -c "echo 'something' >> /etc/privilegedFile"
```

Now check whether logical volume is mounted or not:
[adminUsername@nfs ~]$ sudo df -hP
```console
Filesystem                  Size  Used Avail Use% Mounted on
devtmpfs                    1,7G     0  1,7G   0% /dev
tmpfs                       1,7G     0  1,7G   0% /dev/shm
tmpfs                       1,7G   17M  1,7G   1% /run
tmpfs                       1,7G     0  1,7G   0% /sys/fs/cgroup
/dev/sdb2                    30G  3,6G   26G  13% /
/dev/sdb1                   496M  327M  170M  66% /boot
/dev/sdb15                  495M  7,3M  488M   2% /boot/efi
/dev/mapper/data_vg-nfs_lv   10G  104M  9,9G   2% /srv/nfs
```

Let's install the NFS packages and start the service:
```console
[adminUsername@nfs ~]$ sudo dnf install nfs-utils net-tools -y
Last metadata expiration check: 0:58:17 ago on sáb 20 feb 2021 11:50:08 CET.
Package nfs-utils-1:2.3.3-41.el8.x86_64 is already installed.
Package net-tools-2.0-0.52.20160912git.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
[adminUsername@nfs ~]$ sudo systemctl  enable nfs-server
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /usr/lib/systemd/system/nfs-server.service.
[adminUsername@nfs ~]$ sudo systemctl start nfs-server
```

It is time now to configure the access to the NFS sharedrive, so the file /etc/exports gets updated with the IP's that we want to serve: the master and the workers.

**Issue: When trying to add the IP's to the /etc/exports file you might come across an issue like this:**
```console
[adminUsername@nfs etc]$ sudo vi /etc/exports
```
```vim
/srv/nfs        23.97.221.22(rw,sync)
/srv/nfs        104.46.49.49(rw,sync)
/srv/nfs        104.40.215.208(rw,sync)
~                                                                          
~                                              
"/etc/exports"                                                                                                                                                                                                  
"/etc/exports" E212: Can't open file for writing
Press ENTER or type command to continue
```

**Solution: Change the permissions of the target file before edinting it**
```console
[adminUsername@nfs ~]$ sudo chmod +rwx /etc/exports
[adminUsername@nfs etc]$ sudo cat /etc/exports
/srv/nfs        23.97.221.22(rw,sync)
/srv/nfs        104.46.49.49(rw,sync)
/srv/nfs        104.40.215.208(rw,sync)
```

To apply the configuration changes, just re-read again the file:
```console
[adminUsername@nfs ~]$ sudo exportfs -r
[adminUsername@nfs ~]$ sudo exportfs -s
/srv/nfs  23.97.221.22(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/srv/nfs  104.46.49.49(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/srv/nfs  104.40.215.208(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```
The last step in the process is opening the firewall ports to make the service accessible:

**Issue: Seems that the service is not running**
```console
[adminUsername@nfs ~]$ sudo firewall-cmd --permanent --add-service=nfs
FirewallD is not running
```

**Solution: Enable and start Firewalld**
```console
[adminUsername@nfs ~]$ sudo systemctl enable firewalld
Created symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service → /usr/lib/systemd/system/firewalld.service.
Created symlink /etc/systemd/system/multi-user.target.wants/firewalld.service → /usr/lib/systemd/system/firewalld.service.
[adminUsername@nfs ~]$ sudo systemctl start firewalld
[adminUsername@nfs ~]$ sudo systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2021-02-20 13:12:10 CET; 9s ago
     Docs: man:firewalld(1)
 Main PID: 133144 (firewalld)
    Tasks: 2 (limit: 21696)
   Memory: 23.4M
   CGroup: /system.slice/firewalld.service
           └─133144 /usr/libexec/platform-python -s /usr/sbin/firewalld --nofork --nopid

feb 20 13:12:10 nfs systemd[1]: Starting firewalld - dynamic firewall daemon...
feb 20 13:12:10 nfs systemd[1]: Started firewalld - dynamic firewall daemon.
feb 20 13:12:10 nfs firewalld[133144]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. It will be removed in a future release. Please consider disabling it now.
```
We run again the command to open firewall ports:
```console
[adminUsername@nfs ~]$ sudo firewall-cmd --permanent --add-service=nfs
success
[adminUsername@nfs ~]$ sudo firewall-cmd --permanent --add-service=rpc-bind
success
[adminUsername@nfs ~]$ sudo firewall-cmd --permanent --add-service=mountd
success
[adminUsername@nfs ~]$ sudo firewall-cmd --reload
success
```

