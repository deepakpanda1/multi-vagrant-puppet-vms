# -*- mode: ruby -*-
# vi: set ft=ruby :

# Multi-VM Configuration: WebLogic Application Server and Oracle Database Server
# Author: Gary A. Stafford
# Based on David Lutz's https://gist.github.com/dlutzy/2469037
# Configures VMs based on Hosted Chef Server defined Environment and Node (vs. Roles)

# node and chef configurations from json files
nodes_config = (JSON.parse(File.read("nodes.json")))['nodes']
chef_config  = (JSON.parse(File.read("chef.json")))['chef']

VAGRANTFILE_API_VERSION = "2"

Vagrant.require_plugin "vagrant-omnibus"
  nodes_config.each do |node|
    current_node = node[1]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "vagrant-oracle-vm-saucy64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/saucy/current/saucy-server-cloudimg-amd64-vagrant-disk1.box"

  config.omnibus.chef_version = :latest

    
    # configures all forwarding ports in json file
    ports = current_node['ports']
    ports.each do |port|
      config.vm.network :forwarded_port,
        host:  port[':host'],
        guest: port[':guest'],
        id:    port[':id']
    end

    config.vm.hostname = current_node[':node']
    config.vm.network :private_network, ip: current_node[':ip']

    # syncs local repository of large third-party installer files (quicker than downloading each time)
    config.vm.synced_folder "#{ENV['HOME']}/Documents/git_repos/chef-artifacts", "/vagrant"

    config.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", current_node[':memory']]
      vb.customize ["modifyvm", :id, "--name",   current_node[':node']]
    end

    config.vm.provision :chef_client do |chef|
      chef.environment = chef_config[':environment']
      chef.provisioning_path = chef_config[':provisioning_path']
      chef.chef_server_url = chef_config[':chef_server_url']
      chef.validation_key_path = chef_config[':validation_key_path']
      chef.node_name = node[0]
      chef.validation_client_name = chef_config[':validation_client_name']
      chef.client_key_path = chef_config[':client_key_path']
    end
  end
end