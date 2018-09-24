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



def generate_cni_conf(nodename):
  pod_cidr = v1.read_node(nodename).spec.pod_cidr
  return """{{
  "cniVersion": "0.2.0",
  "name": "scrambler",
  "type": "bridge",
  "bridge": "scrambler0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {{
    "type": "host-local",
    "subnet": "{pod_cidr}",
    "routes": [
      {{ "dst": "0.0.0.0/0" }}
    ]
  }}
}}""".format(pod_cidr=pod_cidr)



if __name__ == '__main__':
  print generate_cni_conf(sys.argv[1])
