# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise64"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # Enable NFS access to the disk
  config.vm.synced_folder "", "/vagrant", :nfs => true

  # NFS requires a host-only network
  config.vm.network :private_network, ip: "10.11.12.13"
  # Forward ports too so that you can access the vm in your local network
  # through your hosts' IP address
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 1080, host: 1080

  # provisioning
  config.vm.provision "shell", path: "script/provision.sh", privileged: false

  config.ssh.forward_agent = true
end
