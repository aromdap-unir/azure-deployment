# Configuration for Master and Workers

## DNS makeup
Configure the DNS in the host file: /etc/hosts
```console
[adminUsername@master ~]$ sudo vi /etc/hosts
```
```vim
40.115.40.134 master master.acme.es
40.115.40.209 workera workera.acme.es
40.115.43.180 workerb workerb.acme.es
40.115.40.71 nfs nfs.acme.es
```
## Firewall masquerading
Activate **transparent masquerading** to allow the POD's to communicate withing the cluster via VXLAN:
```console
[adminUsername@master ~]$ sudo modprobe br_netfilter
[adminUsername@master ~]$ firewall-cmd --add-masquerade --permanent
FirewallD is not running

```

**Issue: FirewallD service does not seem to be active**
```console
[adminUsername@master ~]$ sudo firewall-cmd --add-masquerade --permanent
FirewallD is not running

```

**Solution: Activate service before running ```firewall-cmd```**
```console
[adminUsername@master ~]$ sudo systemctl enable firewalld
Created symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service → /usr/lib/systemd/system/firewalld.service.
Created symlink /etc/systemd/system/multi-user.target.wants/firewalld.service → /usr/lib/systemd/system/firewalld.service.
[adminUsername@master ~]$ sudo systemctl start firewalld
```
Re-run the addition of the masquerade and reload to activate the **transparent masquerading** for the POD's, this time with no issues:
```console
[adminUsername@master ~]$ sudo firewall-cmd --add-masquerade --permanent
success
[adminUsername@master ~]$ sudo firewall-cmd --reload
success
```

To allow Kubernetes to correctly manage the firewall it is a requirement for your Linux Node's iptables to correctly see bridged traffic, you should ensure net.bridge.bridge-nf-call-iptables is set to 1 in your sysctl config, e.g.

**Issue: permission denied when trying to modify the file:**
```console
[adminUsername@master ~]$ sudo bash -c 'sudo cat <<EOF > /etc/sysctl.d/k8s.conf
> net.bridge.bridge-nf-call-ip6tables = 1
> net.bridge.bridge-nf-call-iptables = 1
> EOF'
-bash: /etc/sysctl.d/k8s.conf: Permission denied
```

This is because, even though we are executing the command as ```sudo```, it's trying to open the file with your ***adminUsername*** permissions not those of the process you're running under ```sudo```

**Solution: Bypass permission issues by linking ```sudo``` permissions to ```bash``` process via adding ```bash -c '...'``` to initial command**
```console
[adminUsername@master ~]$ sudo bash -c 'sudo cat <<EOF > /etc/sysctl.d/k8s.conf
> net.bridge.bridge-nf-call-ip6tables = 1
> net.bridge.bridge-nf-call-iptables = 1
> EOF'
```

Appy changes via ```syscltl --system```:
```console
[adminUsername@master ~]$ sudo sysctl --system
* Applying /usr/lib/sysctl.d/10-default-yama-scope.conf ...
kernel.yama.ptrace_scope = 0
* Applying /usr/lib/sysctl.d/50-coredump.conf ...
kernel.core_pattern = |/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %h %e
* Applying /usr/lib/sysctl.d/50-default.conf ...
kernel.sysrq = 16
kernel.core_uses_pid = 1
kernel.kptr_restrict = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.promote_secondaries = 1
net.core.default_qdisc = fq_codel
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
* Applying /usr/lib/sysctl.d/50-libkcapi-optmem_max.conf ...
net.core.optmem_max = 81920
* Applying /usr/lib/sysctl.d/50-pid-max.conf ...
kernel.pid_max = 4194304
* Applying /etc/sysctl.d/99-sysctl.conf ...
* Applying /etc/sysctl.d/k8s.conf ...
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
* Applying /etc/sysctl.conf ...
```
## Swap deactivation

Deactivate the ```swap``` to avoid performance losses and avoid the swap storage to be dumped to different environments, which should be isolated.

First, check the ```swap``` via ```free -m``` command: in our case is not being used, since it is set to a total of zero.
```console
[adminUsername@master ~]$ free -m
              total        used        free      shared  buff/cache   available
Mem:           3424         405         797          16        2221        2716
Swap:             0           0           0
```

However, if we wanted to deactivate it anyway, we could first turn it off and then remove its corresponding line in file ```/etc/fstab```.

```console
[adminUsername@master ~]$ sudo swapoff -a
```

File ```/etc/fstab``` **before** removal:
```console
[adminUsername@master ~]$ cat /etc/fstab 

#
# /etc/fstab
# Created by anaconda on Wed Dec  9 18:11:23 2020
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
UUID=68b1ceb7-053a-4317-b135-b90378cc7d36 /                       xfs     defaults        0 0
UUID=61b21c05-a07f-4812-81f7-fca6f4f27230 /boot                   xfs     defaults        0 0
UUID=3483-08B4          /boot/efi               vfat    defaults,uid=0,gid=0,umask=077,shortname=winnt 0 2
/dev/disk/cloud/azure_resource-part1    /mnt/resource   auto    defaults,nofail,x-systemd.requires=cloud-init.service,comment=cloudconfig       0       2

```

File ```/etc/fstab``` **after** removal:
```console
[adminUsername@master ~]$ sudo sed -i '/swap/d' /etc/fstab
[adminUsername@master ~]$ cat /etc/fstab 

#
# /etc/fstab
# Created by anaconda on Wed Dec  9 18:11:23 2020
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
UUID=68b1ceb7-053a-4317-b135-b90378cc7d36 /                       xfs     defaults        0 0
UUID=61b21c05-a07f-4812-81f7-fca6f4f27230 /boot                   xfs     defaults        0 0
UUID=3483-08B4          /boot/efi               vfat    defaults,uid=0,gid=0,umask=077,shortname=winnt 0 2
/dev/disk/cloud/azure_resource-part1    /mnt/resource   auto    defaults,nofail,x-systemd.requires=cloud-init.service,comment=cloudconfig       0       2
```
> **Notice**: In our case there is no change since ```swap``` was not present in the first instance. But if a line for ```swap``` had exists, it would have been deleted.

## Docker installation
Let's install, enable and start Docker as runtime engine for our Kubernetes ecosystem:
```console
[adminUsername@master ~]$ sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
Adding repo from: https://download.docker.com/linux/centos/docker-ce.repo
[adminUsername@master ~]$ sudo dnf install docker-ce-19.03.14-3.el8 containerd.io -y
...
[adminUsername@master ~]$ sudo systemctl enable docker
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
[adminUsername@master ~]$ sudo systemctl start docker

```
> **Notice**: We have installed ```Docker 19.04``` because at the time of this configuration was the latest tested version of Docker in Kubernetes.

## Kubernetes 
Let's configure the Kubernetes repository:

> **Notice**: Due to permission restrictions, you might have to apply the ```bash -c '...'``` solution already mentioned in this documentation.
```bash
-bash: /etc/yum.repos.d/kubernetes.repo: Permission denied
```
```console
[adminUsername@master ~]$ sudo bash -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
> [kubernetes]
> name=Kubernetes
> baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
> enabled=1
> gpgcheck=1
> repo_gpgcheck=1
> gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
> exclude=kubelet kubeadm kubectl
> EOF'
```
Let's install Kubernetes:
```console
[adminUsername@master ~]$ sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

...
Installed:
  conntrack-tools-1.4.4-10.el8.x86_64         cri-tools-1.13.0-0.x86_64              kubeadm-1.20.4-0.x86_64     kubectl-1.20.4-0.x86_64  kubelet-1.20.4-0.x86_64  kubernetes-cni-0.8.7-0.x86_64  libnetfilter_cthelper-1.0.0-15.el8.x86_64 
  libnetfilter_cttimeout-1.0.0-11.el8.x86_64  libnetfilter_queue-1.0.4-3.el8.x86_64  socat-1.7.3.3-2.el8.x86_64 

Complete!

```
Now, enable and start it:
```console
[adminUsername@master ~]$ sudo systemctl enable kubelet
Created symlink /etc/systemd/system/multi-user.target.wants/kubelet.service → /usr/lib/systemd/system/kubelet.service.
[adminUsername@master ~]$ sudo systemctl start kubelet

```
