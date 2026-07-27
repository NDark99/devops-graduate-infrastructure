Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "devops-graduate"

  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "devops-graduate"
    vb.memory = 4096
    vb.cpus = 2
  end

  config.vm.provision "shell", path: "scripts/bootstrap.sh"
end
