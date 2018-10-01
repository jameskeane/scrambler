# Developing scrambler

## Test Cluster

A sample 3 node cluster can be used for development, using Vagrant.

```
# Install required vagrant plugins
# NOTE: vagrant-cloudinit depends on `mkisofs` make sure it's available,
#       otherwise provisioning will fail.
#       See: https://github.com/jameskeane/vagrant-cloudinit#dependencies
vagrant plugin install vagrant-cloudinit vagrant-hosts

# Bring up the cluster
vagrant up
```

Mkae sure to ignore changes to the `.cluster-join-command` file:
```
git update-index --assume-unchanged .cluster-join-command
```

If you want to add another node to the cluster, change the `NUM_WORKER_NODES`
variable, generate a new join token and bring up the new node vm:
```
vagrant provision --provision-with=create-token && vagrant up
```

At this point it is *highly* recommended to snapshot the cluster **before**
deploying scrambler, in case something gets messed up it's a lot easier to
restore from a snapshot than reprovision from scratch.
```
vagrant snapshot save 'base-cluster'

# Then restore with:
vagrant snapshot restore 'base-cluster' --no-provision
```

**NOTE:** The plugin is not installed to the vagrant cluster automatically, you
must ssh into the master node and run `kubectl apply -f /vagrant/kube-scrambler.yml`.

## Next Steps
 - Create an actual CNI plugin (see kube-net for how to reuse the bridge plugin)
 - Put the CNI config in a config map
 - Not all traffic that could be tunneled between nodes is tunneled through
   ipsec. This is because the cluster is bootstrapped using the node's LAN
   address. Once scrambler is installed we can take over any connection between
   the nodes by adding a custom updown script that creates a netfilter rule to
   rewrite the LAN address to the tunneled address.
 - There is a race condition between vagrant and cloud-init; cloud-init wants to
   start downloading packages, while vagrant wants to change the network
   interfaces and hostname. Since cloud-init runs directly at boot, there is
   no easy way to synchronize this.
   One solution is for the vagrant-cloudinit plugin to take control of the
   network interface and hostname configuration, and embed it into the metadata.
