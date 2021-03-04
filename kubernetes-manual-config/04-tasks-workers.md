# Workers configuration
First of all, we need to open the ports
```console
[adminUsername@worker-a ~]$ sudo systemctl enable firewalld
Created symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service → /usr/lib/systemd/system/firewalld.service.
Created symlink /etc/systemd/system/multi-user.target.wants/firewalld.service → /usr/lib/systemd/system/firewalld.service.
[adminUsername@worker-a ~]$ sudo systemctl start firewalld
[adminUsername@worker-a ~]$ sudo firewall-cmd --zone=public --permanent --add-port={10250,30000-32767}/tcp
success
[adminUsername@worker-a ~]$ sudo firewall-cmd --reload
success
```
Now, join the node to the cluster using the outputs saved from the ouptuts obtained after executing ```sudo kubeadm init --pod-network-cidr 192.169.0.0/16 ``` during the Master's configuration:
```console
[adminUsername@worker-a ~]$ sudo kubeadm join 10.0.1.10:6443 --token fhcdsc.4jgt953c418m527s --discovery-token-ca-cert-hash sha256:341aa5a7339d98d76d6b316bfb95329c75ee98ec7ab347fe2120860e5174ea88
[preflight] Running pre-flight checks
        [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
        [WARNING FileExisting-tc]: tc not found in system path
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```
As you can see, our worker is now **Ready** and can bee seen from the Master's terminal:
```console
[adminUsername@master ~]$ sudo kubectl get nodes
NAME       STATUS   ROLES                  AGE    VERSION
master     Ready    control-plane,master   96m    v1.20.4
worker-a   Ready    <none>                 3m5s   v1.20.4


[adminUsername@master ~]$ sudo kubectl get pods -A -o wide
NAMESPACE         NAME                                      READY   STATUS    RESTARTS   AGE     IP               NODE       NOMINATED NODE   READINESS GATES
calico-system     calico-kube-controllers-56689cf96-pg86r   1/1     Running   0          36m     192.169.219.65   master     <none>           <none>
calico-system     calico-node-2mtv4                         0/1     Running   0          36m     10.0.1.10        master     <none>           <none>
calico-system     calico-node-psr86                         0/1     Running   0          7m58s   10.0.1.12        worker-a   <none>           <none>
calico-system     calico-typha-5ccb746dc4-qzpgq             1/1     Running   0          7m15s   10.0.1.12        worker-a   <none>           <none>
calico-system     calico-typha-5ccb746dc4-vnm6q             1/1     Running   0          36m     10.0.1.10        master     <none>           <none>
kube-system       coredns-74ff55c5b-krq9f                   1/1     Running   0          101m    192.169.219.66   master     <none>           <none>
kube-system       coredns-74ff55c5b-sv5r5                   1/1     Running   0          101m    192.169.219.67   master     <none>           <none>
kube-system       etcd-master                               1/1     Running   0          101m    10.0.1.10        master     <none>           <none>
kube-system       kube-apiserver-master                     1/1     Running   1          101m    10.0.1.10        master     <none>           <none>
kube-system       kube-controller-manager-master            1/1     Running   1          101m    10.0.1.10        master     <none>           <none>
kube-system       kube-proxy-lmlq5                          1/1     Running   0          7m58s   10.0.1.12        worker-a   <none>           <none>
kube-system       kube-proxy-xhh6l                          1/1     Running   0          101m    10.0.1.10        master     <none>           <none>
kube-system       kube-scheduler-master                     1/1     Running   0          101m    10.0.1.10        master     <none>           <none>
tigera-operator   tigera-operator-7c5d47c4b5-frgtj          1/1     Running   1          45m     10.0.1.10        master     <none>           <none>

```
