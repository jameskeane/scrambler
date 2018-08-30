# Scrambler

Scrambler is a simple and easy way to configure an ipsec secured, layer 3 network fabric designed for Kubernetes.

## How it works

TODO

## Getting started on Kubernetes

TODO

## Developing

A sample 3 node cluster can be used for development, using Vagrant.

Install required vagrant plugins
```
vagrant plugin install vagrant-cloudinit vagrant-hosts
```

Bring up the cluster, it will bootstrap the cluster, and automatically join the nodes:
```
vagrant up
```

Ignore changes to the `.cluster-join-command` file:
```
git update-index --assume-unchanged .cluster-join-command
```

If you want to add another node to the cluster, change the `NUM_WORKER_NODES` variable, generate a new join token and bring up the new node vm:
```
vagrant provision --provision-with=create-token && vagrant up
```
