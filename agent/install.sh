#!/bin/bash
set -e

# Generate and drop the CNI config in place
# TODO Don't overwrite an existing config... the rest of the code will read the
# config
CNI_FILE="/etc/cni/net.d/10-scrambler.conf"
./generate-cni.sh $NODENAME > $CNI_FILE

# Extract the subnet and bridge name from the cni conf
NODE_CIDR=$(cat $CNI_FILE | jq -r '.ipam.subnet')
BRIDGE=$(cat $CNI_FILE | jq -r '.bridge')

# Kubernetes will give us the node's cidr (i.e. "10.100.0.0/24"), but we want to
# assign an ip to the host (i.e. 10.100.0.1), by default `ip addr add` will
# allow a network address to be assigned to the bridge, so we "massage" it into
# to a host address (that CNI likes)
CIDR_HOSTMIN_CIDR=$(echo $NODE_CIDR | sed 's/\([0-9]*\.[0-9]*\.[0-9]*\.\)0/\11/')

# Create the bridge, assign the cidr, and bring it up
# NOTE: This has to happen *before* strongswan is started
echo "scrambler: installing bridge $BRIDGE for $CIDR_HOSTMIN_CIDR"
brctl addbr $BRIDGE
ip addr add $CIDR_HOSTMIN_CIDR dev $BRIDGE
ip link set dev $BRIDGE up

# Strongswan creates the xfrm policies that allow routing to anything in the
# cluster cidr, but we need to route packets originating from the $BRIDGE
# to the internet ourselves.
# TODO: See https://wiki.strongswan.org/projects/strongswan/wiki/ForwardingAndSplitTunneling
