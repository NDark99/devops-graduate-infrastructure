Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.hostname = "devops-graduate"

  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "devops-graduate"
    vb.memory = 4096
    vb.cpus = 2
  end

  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "ansible/playbook.yml"
    ansible.install = true
    ansible.install_mode = :default
    ansible.become = true
    ansible.galaxy_role_file = "ansible/requirements.yml"
    ansible.galaxy_command = "ansible-galaxy collection install --requirements-file=%{role_file} --force"
  end
end
