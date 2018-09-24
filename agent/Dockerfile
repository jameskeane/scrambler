FROM ubuntu:18.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    module-init-tools apt-utils iptables iproute2 bridge-utils jq python-pip \
    strongswan

RUN mkdir -p /var/lib/scrambler
WORKDIR /var/lib/scrambler

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY install.sh agent.sh generate_conf.py generate_cni.py /var/lib/scrambler/
