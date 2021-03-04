```console
sudo dnf update -y &&
sudo timedatectl set-timezone Europe/Madrid &&
sudo dnf install chrony -y &&
sudo systemctl enable chronyd &&
sudo systemctl start chronyd &&
sudo timedatectl set-ntp true &&
sudo sed -i s/=enforcing/=disabled/g /etc/selinux/config &&
sudo dnf install nfs-utils nfs4-acl-tools wget -y
```
