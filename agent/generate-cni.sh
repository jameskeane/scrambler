#!/bin/bash

# Generate a valid CNI config for a given kubernetes node. The CNI config is
# pretty simple, it reuses the 'bridge' plugin and allocates the cluster
# defined 'pod cidr' to it.
# 
# The node can be specified either as an env variable ($NODENAME) or through the
# command line (`generate-cni.sh kube-node123`).
source "kubeapi.sh"

: ${NODENAME:=$1}
node_json=$(kubeapi "/nodes/$NODENAME")
pod_cidr=$(echo "$node_json" | jq -r '.spec.podCIDR') # only thing that matters

envsubst <<EOF
{
  "cniVersion": "0.2.0",
  "name": "scrambler",
  "type": "bridge",
  "bridge": "scrambler0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "$pod_cidr",
    "routes": [
      { "dst": "0.0.0.0/0" }
    ]
  }
}
EOF
