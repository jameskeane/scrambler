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

# Strongswan creates the xfrm policies to route traffic destined for a remote
# tunnel. But it does not do anything for other traffic, i.e. the internet,
# traffic between pods running on the same host), etc.

# Accept traffic originating from the pod bridge with the node's CIDR
# (i.e. pod traffic)
iptables -t filter -A FORWARD -s $NODE_CIDR -i $BRIDGE -j ACCEPT \
         -m comment --comment "scrambler pod traffic"

# NOTE: We need to be careful here, that we don't masquerade traffic that
#       strongswan should handle. Strongswan's rules are very narrow and
#       changing the source ip of a packet to outside of a tunneled subnet will
#       prevent strongswan from handling it. Messing this up will cause traffic
#       that *should* be ipsec encrypted to pass in the clear!
#       See: https://wiki.strongswan.org/projects/strongswan/wiki/ForwardingAndSplitTunneling
# The first command tells netfilter to *not* masq traffic with an ipsec policy
# The second command will cause it to masq everything else
iptables -t nat -A POSTROUTING -s $NODE_CIDR \
         -m policy --dir out --pol ipsec -j ACCEPT
iptables -t nat -A POSTROUTING -s $NODE_CIDR ! -o $BRIDGE -j MASQUERADE
