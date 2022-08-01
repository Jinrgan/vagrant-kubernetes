# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.6.0"

boxes = [
  {
    :name => "master",
    :eth1 => "192.168.0.203",
    :mem => "4096",
    :cpu => "2" # at least 2
  },
  {
    :name => "worker1",
    :eth1 => "192.168.0.204",
    :mem => "4096",
    :cpu => "2"
  },
  {
    :name => "worker2",
    :eth1 => "192.168.0.205",
    :mem => "4096",
    :cpu => "2"
  }
]

Vagrant.configure(2) do |config|
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.provision "shell", inline: <<-SHELL
      echo "192.168.0.203 master" >> /etc/hosts
      echo "192.168.0.204 worker1" >> /etc/hosts
      echo "192.168.0.205 worker2" >> /etc/hosts
  SHELL
  config.vm.box = "centos/7"
  config.vm.box_url = "https://mirrors.ustc.edu.cn/centos-cloud/centos/7/vagrant/x86_64/images/CentOS-7.box"
  boxes.each do |opts|
    config.vm.define opts[:name] do |config|
      config.vm.hostname = opts[:name]
      config.vm.provider "vmware_fusion" do |v|
        v.vmx["memsize"] = opts[:mem]
        v.vmx["numvcpus"] = opts[:cpu]
      end
      config.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", opts[:mem]]
        v.customize ["modifyvm", :id, "--cpus", opts[:cpu]]
      end
      config.vm.network :public_network, bridge: "em1", ip: opts[:eth1]
    end
  end
  config.vm.provision "shell", privileged: true, path: "./setup.sh"
end
