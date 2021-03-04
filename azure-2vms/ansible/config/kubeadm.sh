#!/bin/sh
kubeadm join 10.0.1.10:6443 --token p6pk6q.lx3l2z7094ksj9jx \
    --discovery-token-ca-cert-hash sha256:1ef2577a144325bd38e0ec3cde78c7b328fea749b3069dc90d16da14a2c76b3e 
