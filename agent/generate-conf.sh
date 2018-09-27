#!/bin/bash

# Generate an ipsec.conf for a given node that defines the ipsec mesh network
# between each nodes in the cluster. Nodes are identified and authenticated by
# their certificate identity and verified by the shared cluster CA.
# 
# The node can be specified either as an env variable ($NODENAME) or through the
# command line (`generate-conf.sh kube-node123`).
source "kubeapi.sh"

# Helper method to extract just fields we care about from the node json
extract_node_info() {
  jq -r '{
    name: .metadata.name,
    pod_cidr: .spec.podCIDR,
    ip_addresses: .status.addresses | map(select(.type == "InternalIP")) | map(.address) | join(",")
  }'
}

: ${NODENAME:=$1}

# First we will define the 'local' side of the connections (as 'left'), the
# remote will be the 'right' side of the connection
json_assoc 'local_node' <<< $(kubeapi "/nodes/$NODENAME" | extract_node_info)

envsubst <<EOF
config setup
    charondebug="ike 1, knl 2, cfg 1"

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=%forever # keep trying to establish connection
    keyexchange=ikev2
    dpdaction=restart # restart if the tunnel dies
    leftcert=kubelet-client.crt
    left=${local_node[ip_addresses]}
    leftsubnet=${local_node[pod_cidr]}
    leftfirewall=yes
    leftsendcert=ifasked

EOF

# Now define the peering connections... since we are creating a mesh network,
# every other node in the cluster must be declared.
# --
# read all of the node objects into an array and loop over them
IFS=$'\n' node_defs=( $(kubeapi '/nodes' | jq -c '.items[]') )
for node in "${node_defs[@]}"; do
  json_assoc "current_node" <<< $(echo $node | extract_node_info)

  # skip this node if it's the same as the local node. We only care about the
  # remote nodes
  [ ${current_node[name]} == ${local_node[name]} ] && continue

  # print out the 'right' side config
  envsubst <<EOF
conn ${current_node[name]}
    right=${current_node[ip_addresses]}
    rightsubnet=${current_node[pod_cidr]}
    rightid="O=system:nodes, CN=system:node:${current_node[name]}"
    auto=start
EOF
done
