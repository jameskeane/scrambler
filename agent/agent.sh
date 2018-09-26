#!/bin/bash

cacert="/etc/kubernetes/pki/ca.crt"
certfile="/var/lib/kubelet/pki/kubelet-client-current.pem"
ipsec_priv="/etc/ipsec.d/private/kubelet-client.key"
ipsec_cacert="/etc/ipsec.d/cacerts/kubernetes.crt"
ipsec_cert="/etc/ipsec.d/certs/kubelet-client.crt"


# Check if certs and ipsec.conf need to be updated, if so update and reload them
update_if_needed() {
  # If any of the certificates have been updates we need to reload them
  if [ "$certfile" -nt "$ipsec_cert" ] || [ "$cacert" -nt "$ipsec_cacert" ]; then
    # Copy the certs into the right place
    # striping pubkey from the priv and priv from the pub (Strongswan doesn't
    # like mixed pems).
    cp "$cacert" "$ipsec_cacert"
    openssl x509 -in "$certfile" -outform pem -out "$ipsec_cert" > /dev/null
    openssl ec -in "$certfile" -outform pem -out "$ipsec_priv" > /dev/null

    # Instruct ipsec to reread everything
    ipsec rereadall || true
  fi

  # Get the latest config, and diff with the currently used one
  # if it's changed then write it and reload
  latest_conf=$(./generate-conf.sh $NODENAME)
  echo "$latest_conf" | diff -s /etc/ipsec.conf - > /dev/null
  if [ $? -ne 0 ]; then
    echo "Cluster configuration has changed, updating network config"

    echo "$latest_conf" > /etc/ipsec.conf
    ipsec update || true
  fi
}


# load initial config
update_if_needed

# Tell strongswan to read the private key 
echo ": ECDSA kubelet-client.key" > /etc/ipsec.secrets

# Start the ipsec daemon
# Not sure why we have to redirect stdio, but docker wasn't printing stdout
# until I did this...
ipsec start --nofork > /dev/stdout 2> /dev/stderr &

# Loop and update the config if needed, i.e. certs get rotated or
# nodes added/removed
while :; do
  update_if_needed

  # TODO, we can improve this using inotifywait and k8s api watcher
  sleep 10
done

# Make sure we stop the ipsec bg process
trap ctrl_c INT TERM;
ctrl_c() {
  ipsec stop
  exit 1
}
