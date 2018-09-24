import sys
from kubernetes import client, config

# Load config from either local or cluster ways
# keeping this is useful for development, so it can be run directly on a master
# node
try:
  config.load_kube_config()
except:
  config.load_incluster_config()

v1 = client.CoreV1Api()



def config_template(local_node, other_nodes):
  node_configs = [
    """
conn {node[name]}
    right={node[ip_addresses]}
    rightsubnet={node[pod_cidr]}
    rightid="O=system:nodes, CN=system:node:{node[name]}"
    auto=start
    """.format(node=node) for node in other_nodes
  ]

  return """
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
    left={local_node[ip_addresses]}
    leftsubnet={local_node[pod_cidr]}
    leftfirewall=yes
    leftsendcert=ifasked
""".format(local_node=local_node) + "".join(node_configs)


def extract_node_info(node):
  ipv4_addresses = [x.address for x in node.status.addresses if x.type == 'InternalIP']
  hostnames = [x.address for x in node.status.addresses if x.type == 'Hostname']

  return {
    'name': node.metadata.name,
    'hostnames': hostnames,
    'ip_addresses': ",".join(ipv4_addresses),
    'pod_cidr': node.spec.pod_cidr
  }


def get_node_by_name(name, nodes):
  for node in nodes:
    if node['name'] == name: return node
  raise Exception("Can't find node %s" % name)


def generate_ipsec_conf(local_nodename):
  # Get all nodes from k8s api
  ret = v1.list_node()

  # extract the node info we care about and print the generate template
  all_nodes = [extract_node_info(node) for node in ret.items]
  local_node = get_node_by_name(local_nodename, all_nodes)
  other_nodes = [node for node in all_nodes if node != local_node]

  print config_template(local_node, other_nodes)


if __name__ == '__main__':
  generate_ipsec_conf(sys.argv[1])
