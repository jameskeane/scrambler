#!/usr/bin/env bash

# Initialize the cluster master
sudo kubeadm init \
    --apiserver-advertise-address "$MASTER_IP" \
    --pod-network-cidr "$POD_NETWORK_CIDR" \
    --service-cidr "$SERVICE_CIDR"

# Enable kubectl for the current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Enable bash completion
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
