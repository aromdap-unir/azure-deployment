# Kubernetes configuration on Master

Configure the firewall to allow the traffic for Kubernetes services:
```console
[adminUsername@master ~]$ sudo firewall-cmd --permanent --add-port=6443/tcp
success
[adminUsername@master ~]$ sudo firewall-cmd --permanent --add-port=2379-2380/tcp
success
[adminUsername@master ~]$ sudo firewall-cmd --permanent --add-port=10250/tcp
success
[adminUsername@master ~]$ sudo firewall-cmd --permanent --add-port=10251/tcp
success
[adminUsername@master ~]$ sudo firewall-cmd --permanent --add-port=10252/tcp
success
[adminUsername@master ~]$ sudo firewall-cmd --permanent --add-port=10255/tcp
success
[adminUsername@master ~]$ sudo firewall-cmd --reload
success

```
> **Notice**: Port 10255 is used to retrieve statistical data and it should be only accessed by the Masters.

| Protocol | Direction | Port Range | Purpose | Used by |
|----------|-----------|------------|---------|---------|
| TCP | Inbound  | 6443 | Kubernetes API Server | All |
| TCP | Inbound  | 2379-2380 | etcd server client API | kube-apiserver, etcd |
| TCP | Inbound  | 10250 | Kubelet API | self, Control Plane |
| TCP | Inbound  | 10251 | kube-scheduler | self |
| TCP | Inbound  | 10252 | kube-controller-manager| self |
| TCP | Inbound  | 10255 | Statistics | Master nodes |

Configure ```kudeadm```:
```console
[adminUsername@master ~]$ sudo kubeadm config images pull
[config/images] Pulled k8s.gcr.io/kube-apiserver:v1.20.4
[config/images] Pulled k8s.gcr.io/kube-controller-manager:v1.20.4
[config/images] Pulled k8s.gcr.io/kube-scheduler:v1.20.4
[config/images] Pulled k8s.gcr.io/kube-proxy:v1.20.4
[config/images] Pulled k8s.gcr.io/pause:3.2
[config/images] Pulled k8s.gcr.io/etcd:3.4.13-0
[config/images] Pulled k8s.gcr.io/coredns:1.7.0
```

Allow traffic from Workers:
> **Notice**: This is not a good practice. In a production scenario we should allow only the needed trafic, and not all traffic between Master and Workers.
```console
[adminUsername@master ~]$ sudo firewall-cmd --permanent --add-rich-rule 'rule family=ipv4 source address=40.115.40.209/32 accept'
success
[adminUsername@master ~]$ sudo firewall-cmd --permanent --add-rich-rule 'rule family=ipv4 source address=40.115.43.180/32 accept'
success
[adminUsername@master ~]$ sudo firewall-cmd --reload
success
```
Allosw access from containers to localhost:
```console
[adminUsername@master ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0d:3a:44:64:88 brd ff:ff:ff:ff:ff:ff
    inet 10.0.1.10/24 brd 10.0.1.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::20d:3aff:fe44:6488/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:c7:f0:00:6f brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
[adminUsername@master ~]$ sudo firewall-cmd --zone=public --permanent --add-rich-rule 'rule family=ipv4 source address=172.17.0.0/16 accept'
success
[adminUsername@master ~]$ sudo firewall-cmd --reload
success

```
Install the Kubernetes plugin CNI (Container Network Interface) and define the POD's:
> **Notice**: Save the ouput from the command. ***You will need it*** to linke the workers to the cluster.
```console
[adminUsername@master ~]$ sudo kubeadm init --pod-network-cidr 192.169.0.0/16 --ignore-preflight-errors=all
[init] Using Kubernetes version: v1.20.4
[preflight] Running pre-flight checks
        [WARNING NumCPU]: the number of available CPUs 1 is less than the required 2
        [WARNING Firewalld]: firewalld is active, please ensure ports [6443 10250] are open or your cluster may not function correctly
        [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
        [WARNING FileExisting-tc]: tc not found in system path
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local master] and IPs [10.96.0.1 10.0.1.10]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [localhost master] and IPs [10.0.1.10 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [localhost master] and IPs [10.0.1.10 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[kubelet-check] Initial timeout of 40s passed.
[apiclient] All control plane components are healthy after 100.003233 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.20" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node master as control-plane by adding the labels "node-role.kubernetes.io/master=''" and "node-role.kubernetes.io/control-plane='' (deprecated)"
[mark-control-plane] Marking the node master as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: fhcdsc.4jgt953c418m527s
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.1.10:6443 --token fhcdsc.4jgt953c418m527s \
    --discovery-token-ca-cert-hash sha256:341aa5a7339d98d76d6b316bfb95329c75ee98ec7ab347fe2120860e5174ea88 

```
> ***Important***: The command above has been executed with a ```--ignore-preflight-errors=all``` flag to ignore the [preflight] critical error that was been through due to CPU limitations on Master. Minimum CPU's recommended is 2. We have 1 for testing purposes. Below you can see the error we were getting when running the command without the ignore indication.
```
[adminUsername@master ~]$ sudo kubeadm init --pod-network-cidr 192.169.0.0/16
[init] Using Kubernetes version: v1.20.4
[preflight] Running pre-flight checks
        [WARNING Firewalld]: firewalld is active, please ensure ports [6443 10250] are open or your cluster may not function correctly
        [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
        [WARNING FileExisting-tc]: tc not found in system path
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```
It is really important that the network for the POD's has IP's enough to offer to the total of containers that we want to build, and also important to avoid an overlap with already existing networks.

For the current example, we have used a network of Class C, which has a **65536** IP's.

Let's authorise the user to access the cluster to finish the configuration:
```console
[adminUsername@master ~]$ sudo mkdir -p /root/.kube
[adminUsername@master ~]$ sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
[adminUsername@master ~]$ sudo chown $(id -u):$(id -g) /root/.kube/config
[adminUsername@master ~]$ sudo kubectl get nodes
NAME     STATUS     ROLES                  AGE   VERSION
master   NotReady   control-plane,master   34m   v1.20.4
```
We can see that the nod status is "NotReady". This is because we have not deployed they the network for the POD's.

## SDN installation

For the current example, we have chosen Calico as our SDN platform. We need to install the Tigera's operator:
```console
[adminUsername@master ~]$ sudo kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/installations.operator.tigera.io created
customresourcedefinition.apiextensions.k8s.io/tigerastatuses.operator.tigera.io created
namespace/tigera-operator created
podsecuritypolicy.policy/tigera-operator created
serviceaccount/tigera-operator created
clusterrole.rbac.authorization.k8s.io/tigera-operator created
clusterrolebinding.rbac.authorization.k8s.io/tigera-operator created
deployment.apps/tigera-operator created
```
We now install Calico along with all custom resources that it needs. In order to do so, we download, first, the definition file:
```console
[adminUsername@master ~]$ sudo wget https://docs.projectcalico.org/manifests/custom-resources.yaml
--2021-02-20 19:22:11--  https://docs.projectcalico.org/manifests/custom-resources.yaml
Resolving docs.projectcalico.org (docs.projectcalico.org)... 18.157.247.174, 167.99.137.12, 2a05:d014:275:cb00:29f:95e8:f0de:2bdd, ...
Connecting to docs.projectcalico.org (docs.projectcalico.org)|18.157.247.174|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 545 [text/yaml]
Saving to: ‘custom-resources.yaml’

custom-resources.yaml                                      100%[========================================================================================================================================>]     545  --.-KB/s    in 0s      

2021-02-20 19:22:12 (38,2 MB/s) - ‘custom-resources.yaml’ saved [545/545]

```
Now, change the **CIDR** to make it match with the one from our POD's network in the ***custom-resources.yaml***:

In your current working folder, you will see the file. Open it directly with ```vi```:
```console
[adminUsername@master ~]$ ls
custom-resources.yaml
[adminUsername@master ~]$ sudo vi custom-resources.yaml 
```
- Before:
```yaml
# This section includes base Calico installation configuration.
# For more information, see: https://docs.projectcalico.org/v3.17/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
```
- After:

```yaml
# This section includes base Calico installation configuration.
# For more information, see: https://docs.projectcalico.org/v3.17/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: 192.169.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
```
Afterwards, install Calico:
```console
[adminUsername@master ~]$ sudo kubectl apply -f custom-resources.yaml
installation.operator.tigera.io/default created
```
After some minutes we will be able to see the cluster as **Ready**:
```console
[adminUsername@master ~]$ sudo kubectl get nodes
NAME     STATUS   ROLES                  AGE   VERSION
master   Ready    control-plane,master   66m   v1.20.4

[adminUsername@master ~]$ sudo kubectl get pods -A -o wide
NAMESPACE         NAME                                      READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
calico-system     calico-kube-controllers-56689cf96-pg86r   1/1     Running   0          14m   192.169.219.65   master   <none>           <none>
calico-system     calico-node-2mtv4                         1/1     Running   0          14m   10.0.1.10        master   <none>           <none>
calico-system     calico-typha-5ccb746dc4-vnm6q             1/1     Running   0          14m   10.0.1.10        master   <none>           <none>
kube-system       coredns-74ff55c5b-krq9f                   1/1     Running   0          79m   192.169.219.66   master   <none>           <none>
kube-system       coredns-74ff55c5b-sv5r5                   1/1     Running   0          79m   192.169.219.67   master   <none>           <none>
kube-system       etcd-master                               1/1     Running   0          80m   10.0.1.10        master   <none>           <none>
kube-system       kube-apiserver-master                     1/1     Running   1          80m   10.0.1.10        master   <none>           <none>
kube-system       kube-controller-manager-master            1/1     Running   1          80m   10.0.1.10        master   <none>           <none>
kube-system       kube-proxy-xhh6l                          1/1     Running   0          79m   10.0.1.10        master   <none>           <none>
kube-system       kube-scheduler-master                     1/1     Running   0          80m   10.0.1.10        master   <none>           <none>
tigera-operator   tigera-operator-7c5d47c4b5-frgtj          1/1     Running   1          23m   10.0.1.10        master   <none>           <none>

```
> **Notice**: Calico is not your only option when it comes to SDN [Kubernetes networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/).

Let's check the Master's network configuration:
```console
[adminUsername@master ~]$ ip a 
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0d:3a:44:64:88 brd ff:ff:ff:ff:ff:ff
    inet 10.0.1.10/24 brd 10.0.1.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::20d:3aff:fe44:6488/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:c7:f0:00:6f brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
4: cali20e7e0aad9d@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
5: cali5f01a0ffc93@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
8: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    link/ether 66:4f:26:ae:af:db brd ff:ff:ff:ff:ff:ff
    inet 192.169.219.64/32 scope global vxlan.calico
       valid_lft forever preferred_lft forever
    inet6 fe80::644f:26ff:feae:afdb/64 scope link 
       valid_lft forever preferred_lft forever
9: cali429028346ad@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default 
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::ecee:eeff:feee:eeee/64 scope link 
       valid_lft forever preferred_lft forever
```
