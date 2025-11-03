# Vagrantfile for k3s cluster (1 master + N agents)
VAGRANT_EXPERIMENTAL = "typed_triggers"

# --- Load local overrides (ignored by Git) ---
local_config = File.join(File.dirname(__FILE__), ".vagrant-local.rb")
load local_config if File.exist?(local_config)

Vagrant.configure("2") do |config|
  config.vm.box = "michaelricharding/ubuntu-noble64"  # Ubuntu 24.04 LTS

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  # --- Default values (safe to commit) ---
  BRIDGE ||= "default"
  DNS_SERVER ||= "8.8.8.8"
  GITHUB_USER ||= ENV.fetch("GITHUB_USER", "your-github-username")
  NODES ||= [
    { name: "k3s-master", ip: "192.168.56.10", role: "master" },
    { name: "k3s-node1",  ip: "192.168.56.11", role: "agent"  },
    { name: "k3s-node2",  ip: "192.168.56.12", role: "agent"  },
    { name: "k3s-node3",  ip: "192.168.56.13", role: "agent"  },
  ]

  # --- Shared setup for all nodes ---
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    echo "nameserver #{DNS_SERVER}" | sudo tee /etc/resolv.conf
    echo "[+] Importing GitHub keys for #{GITHUB_USER}..."
    mkdir -p /home/vagrant/.ssh
    curl -sfL https://github.com/#{GITHUB_USER}.keys -o /home/vagrant/.ssh/github_keys
    cat /home/vagrant/.ssh/github_keys >> /home/vagrant/.ssh/authorized_keys
    chmod 600 /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
  SHELL

  # --- Define all nodes ---
  NODES.each do |node|
    config.vm.define node[:name] do |vm|
      vm.vm.hostname = node[:name]
      vm.vm.network "public_network", ip: node[:ip], bridge: BRIDGE

      if node[:role] == "master"
        vm.vm.provision "shell", inline: <<-SHELL
          set -e
          echo "[+] Installing k3s server on #{node[:name]}..."
          curl -sfL https://get.k3s.io | sh -s - \
            --write-kubeconfig-mode 644 \
            --token some_secure_token \
            --node-taint CriticalAddonsOnly=true:NoExecute \
            --bind-address #{node[:ip]} \
            --disable=traefik --disable=servicelb
          sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
          echo "[+] #{node[:name]} setup complete."
        SHELL
      else
        vm.vm.provision "shell", inline: <<-SHELL
          set -e
          echo "[+] Installing k3s agent on #{node[:name]}..."
          until [ -f /vagrant/node-token ]; do
            echo "Waiting for master token..."
            sleep 5
          done
          TOKEN=$(cat /vagrant/node-token)
          MASTER_IP=#{NODES.first[:ip]}
          curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_IP:6443" K3S_TOKEN="$TOKEN" sh -
          echo "[+] #{node[:name]} joined the cluster."
        SHELL
      end
    end
  end
end
