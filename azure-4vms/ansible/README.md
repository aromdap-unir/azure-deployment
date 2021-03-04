# Step by step

## Disclaimer

You might run into issues if you try to use Ansible against NFS VMs if you have already configure them manually.

To reproduce this isse, first of all, we have composed the inventory with the variables for Ansible and the different hosts groups:
```vim
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=adminUsername

[common]
40.115.40.134
40.115.40.209
40.115.43.180
40.115.40.71

[nfs]
40.115.40.71

[master-workers]
40.115.40.134
40.115.40.209
40.115.43.180

[master]
40.115.40.134

[workers]
40.115.40.209
40.115.43.180

```
Afterwards, do a ping to the virtual machines:
```diff
adrian:~/Documents/UNIR/Practice/caso-practico-2/azure-deployment/ansible(dev)$ ansible -i inventory -m ping all
[WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details
The authenticity of host '40.115.43.180 (40.115.43.180)' can't be established.
ECDSA key fingerprint is SHA256:48SlOu5NG5vUbFiZJ2flBi3cIEdRbwadIn/hqXcx498.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
40.115.40.209 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
40.115.40.134 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
- 40.115.40.71 | UNREACHABLE! => {
-    "changed": false,
-    "msg": "Failed to connect to the host via ssh: ssh: connect to host -40.115.40.71 port 22: Connection timed out",
-    "unreachable": true
-}
40.115.43.180 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}

```
We have an error. This is because we have configured first manually the NFS server and now it seems to fail when stablishing an ```ssh``` connection. Apparently, this issue is related to the manual addition to file ```/etc/fstab``` and it can be solved by modifying the way we have edited the line:
- The problematic line in ```/etc/fstab```, when manually edited:
```vim
10.0.0.1:/export/share /mnt/shared nfs auto 0 0
```
- The proposed line for ```/etc/fstab```:
```vim
10.0.0.1:/export/share /mnt/shared nfs _netdev,noatime,intr,auto 0 0
```

> **Notice**: Further details can be found [here](https://unix.stackexchange.com/questions/72840/ssh-connections-not-accepted-after-configuring-nfs).

After destroying and building new virtual machines, the inventory.yaml file would look like this:
```yaml
all:
  vars:
    ansible_python_interpreter: /usr/bin/python3
    ansible_user: adminUsername
  hosts:
    13.69.76.43:
    40.68.103.121:
    40.68.204.185:
    40.68.102.209:
  children:
    nfs:
      hosts:
        13.69.76.43:
    master:
      hosts:
        13.69.76.43:
    workers:
      hosts:
        40.68.204.185:
        40.68.102.209:
```

And the outcome of the ping is successfull:
```console
adrian:~/Documents/UNIR/Practice/caso-practico-2/azure-deployment/ansible(dev)$ ansible -i inventory.yaml -m ping all
40.68.102.209 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
13.69.76.43 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
40.68.204.185 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
40.68.103.121 | SUCCESS => {
    "changed": false,
    "ping": "pong"
```

Let's continue with the common tasks to be performed on all VMs, like system updates, enabling and starting services and installation of common packages.

To do so, we have run our first Ansible Playbook:
```yaml
- hosts: all
  become: yes

  tasks:
    - name: Update all Centos8 virtual machines
      dnf: 
        name: "*"
        state: latest

  tasks:
    - name: Update time/date zone of virtual machines
      command: timedatectl set-timezone Europe/Madrid

  tasks:
    - name: Install and enable chronyd
      dnf: 
        name: chrony
        state: latest
      ansible.builtin.systemd:
        name: chronyd
        state: started
        enabled: yes
      command: timedatectl set-ntp true

  tasks:
    - name: Disable SElinux
      command: sed -i s/=enforcing/=disabled/g /etc/selinux/config

  tasks: 
    - name: Instal NFS modues and wget
      dnf: 
        name: ['nfs-utils','nfs4-acl-tools','wget']
        state: latest
```

> **Notice**: we have made use of some built-in Ansible modules, like ```dnf``` and ```systemd```, but you could achive the same by using the ```command``` statement.

> **Notice**: to install several packages with ```dnf``` do not use the deprecated form of ```name: '{{ item }}'``` and, instead, pass a ```python``` list to the name parameter.

To run the playbook, simply:
```console
adrian:~/Documents/UNIR/Practice/caso-practico-2/azure-deployment/ansible(dev)$ ansible-playbook -i inventory.yaml 00-config-all.yaml
```


# Issues:

- Unmounting the system fiel /dev/sdb1 for logical volumes
- Adding the services to firewalld in playbook, due to Ansible version
- Creating kubernetes.repo
- Obtaining the command to join clusters
- Changing the ownership of the /root/.kube/config
- Not able to join worker to master cluster:
    Solution: sudo systemctl disable firewalld --now
    
