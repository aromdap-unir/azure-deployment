#!/bin/sh
kubeadm join 10.0.1.10:6443 --token s7nflh.wrxma97v6h3qkqfg \
    --discovery-token-ca-cert-hash sha256:d0d224b179fa87217caec23bc1b2363c4a1ffdeecaf68e7d5bad8ef207db68b5 
