# Scrambler

Scrambler is a simple and easy way to configure an IPsec mesh overlay network designed for Kubernetes.

## How it works

Scrambler works by leveraging [strongSwan](https://www.strongswan.org/) to create an IPsec mesh overlay network between all cluster nodes. The mesh network is authenticated and encrypted using Kubernetes' PKI certificates, making it exceptionally resilient and secure.

For more information on how Kubernetes uses PKI certificates, see https://kubernetes.io/docs/setup/certificates/

## Getting started on Kubernetes

Scrambler can easily be added to a "standard cluster" (currently tested on kubeadm). In the
future, support for more customized clusters will be added using the `configz`
api.

```
kubectl apply -f https://raw.githubusercontent.com/jameskeane/scrambler/master/kube-scrambler.yml
```

**NOTE:** Scrambler currently requires the control plane to allocate node cidrs. This means using `--pod-network-cidr` with `kubeadm init` or ensuring your controller manager is run with `--cluster-cidr` set.  

## Documentation
 * [Developing](docs/developing.md)

## Contact
 * Bugs: [issues](https://github.com/jameskeane/scrambler/issues)
