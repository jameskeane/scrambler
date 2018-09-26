#!/bin/bash

# A small shell wrapper around the Kubernetes API, by default it will attempt to
# access the api using the configured service account (if available), otherwise
# it will attempt to read the configuration using `kubectl`.
# NOTE: This script can also be used without a service account or kubectl by
#       setting the following environment variables:
#         1. KUBERNETES_SERVICE_URL=<The full url to the api server, i.e. https://ip:port>
#         2. KUBERNETES_CA_CERT_PATH=<The path to the CA authority>
#         3. KUBERNETES_TOKEN=<The bearer token for authentication>

config_get_token() {
  local service_token_path="/var/run/secrets/kubernetes.io/serviceaccount/token"

  if [ -f $service_token_path ]; then
    cat $service_token_path
  else
    kubectl describe secret $(kubectl get secrets | grep ^default | cut -f1 -d ' ') | grep -E '^token' | cut -f2 -d':' | tr -d " "
  fi
}

config_get_cacert() {
  local service_ca_path="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
  if [ -f $service_ca_path ]; then
    echo $service_ca_path
  else
    echo "/etc/kubernetes/pki/ca.crt"
  fi
}

config_get_api_url() {
  if [ -z "$KUBERNETES_SERVICE_HOST" ]; then
    kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " "
  else
    echo "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT"
  fi
}

: ${KUBERNETES_SERVICE_URL:=$(config_get_api_url)}
: ${KUBERNETES_CA_CERT_PATH:=$(config_get_cacert)}


# TODO would be better to do kubectl config view --raw
if [ -z $KUBERNETES_CLIENT_CERT_PATH ] && [ -f "/var/lib/kubelet/pki/kubelet-client-current.pem" ]; then
  KUBERNETES_CLIENT_CERT_PATH="/var/lib/kubelet/pki/kubelet-client-current.pem"
else
  : ${KUBERNETES_TOKEN:=$(config_get_token)}
fi


# Call the kubernetes API
# Usage:
#  - kubeapi '/nodes'
#  - kubeapi '/pods/<pod name>'
#  - etc.
kubeapi() {
  local api_path=$1

  if [ ! -z $KUBERNETES_CLIENT_CERT_PATH ]; then
    curl -sS \
         --cacert $KUBERNETES_CA_CERT_PATH \
         --cert $KUBERNETES_CLIENT_CERT_PATH \
         $KUBERNETES_SERVICE_URL/api/v1$api_path
  else
    curl -sS \
         --cacert $KUBERNETES_CA_CERT_PATH \
         --header "Authorization: Bearer $KUBERNETES_TOKEN" \
         $KUBERNETES_SERVICE_URL/api/v1$api_path
  fi
}


# Convert a JSON object into a bash associative array
# $1 - the desired variable name
# stdin - the json
# Usage:
#   - json_assoc "obj" <<< '{ "example": 1 }'
#     echo ${obj[example]} # prints '1'
json_assoc() {
  local obj_name=$1
  local assoc_def=$(jq -r 'to_entries | map("[" + .key + "]=\"" + .value + "\"") | join(" ")')
  eval "declare -gA $obj_name=($assoc_def)"
}
