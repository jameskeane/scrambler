FROM ubuntu:18.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    module-init-tools iptables iproute2 bridge-utils jq strongswan \
    curl gettext-base
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/scrambler
WORKDIR /var/lib/scrambler

COPY install.sh agent.sh generate-conf.sh generate-cni.sh kubeapi.sh /var/lib/scrambler/
