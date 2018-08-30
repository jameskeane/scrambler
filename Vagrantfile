
# Controls the '--pod-network-cidr' parameter to kubeadm init
POD_NETWORK_CIDR = "10.100.0.0/16"

# Controls the '--service-cidr' parameter to kubeadm init
SERVICE_CIDR     = "10.96.0.0/16"

# How many worker nodes?
NUM_WORKER_NODES = 2


Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"


  # Sync hostnames between machines (using vagrant-hosts)
  config.vm.provision :hosts, sync_hosts: true

  # Provision each vm using cloud-init (using vagrant-cloudinit)
  config.vm.provision :cloud_init, wait: true, user_data: "./user-data.yml"


  # The master node
  # ===
  config.vm.define "master" do |master|
    master.vm.hostname = "kube-master0"
    master.vm.network "private_network", ip: "192.168.96.11"

    # Initialize the cluster
    master.vm.provision "master-bootstrap",
      type: "shell",
      path: "scripts/bootstrap-master.sh",
      privileged: false,
      env: {
        MASTER_IP: "192.168.96.11",
        POD_NETWORK_CIDR: POD_NETWORK_CIDR,
        SERVICE_CIDR: SERVICE_CIDR
      }

    # Create a join token, and save it to a file in the shared folder, so we can
    # use it for the nodes
    master.vm.provision "create-token",
      type: "shell",
      inline: 'kubeadm token create --description "Dynamic cluster scaling token" --ttl 10m --print-join-command > /vagrant/.cluster-join-command'

  end


  # The worker nodes
  # ===
  (0..NUM_WORKER_NODES-1).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "kube-node#{i}"
      node.vm.network "private_network", ip: "192.168.96.#{22+i}"

      # Join the cluster -- run the join token generated earlier
      node.vm.provision "node#{i}-join",
        type: "shell",
        path: ".cluster-join-command"

    end
  end


  # tell virtualbox to use 'linked'/shallow clones; makes starting a bit faster
  config.vm.provider(:virtualbox) {|vb| vb.linked_clone = true}
end

