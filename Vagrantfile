NUM_WORKER_NODES=2
IP_NW="192.168.1."
IP_START=50

Vagrant.configure("2") do |config|
  config.vm.provision "shell", env: {"IP_NW" => IP_NW, "IP_START" => IP_START}, inline: <<-SHELL
      echo "$IP_NW$((IP_START)) node0" >> /etc/hosts
      echo "$IP_NW$((IP_START+1)) node1" >> /etc/hosts
      echo "$IP_NW$((IP_START+2)) node2" >> /etc/hosts
  SHELL

  config.vm.provision "shell", path: "sshkey.sh"
  config.vm.box = "bento/ubuntu-22.04"
  # config.vm.box = "generic/ubuntu2010"
  config.vm.box_check_update = false

  config.vm.define "master" do |master|
    # master.vm.box = "bento/ubuntu-18.04"
    master.vm.hostname = "master"
    master.vm.network "public_network", ip: IP_NW + "#{IP_START}"
    master.vm.provider "vmware_desktop" do |vb|
        vb.memory = 4048
        vb.cpus = 2
        vb.vmx["virtualhw.version"] = "17"  # 指定兼容的硬件版本
        vb.vmx["vmci0.version"] = "0"       # 禁用或降级 VMCI
    end

    master.vm.provision "shell", path: "scripts/common.sh"
    master.vm.provision "shell", path: "scripts/master.sh"
  end

  (1..NUM_WORKER_NODES).each do |i|

  config.vm.define "node#{i}" do |node|
    node.vm.hostname = "node#{i}"
    node.vm.network "public_network", ip: IP_NW + "#{IP_START + i}"
    node.vm.provider "vmware_desktop" do |vb|
        vb.memory = 2048
        vb.cpus = 1
        vb.vmx["virtualhw.version"] = "17"  # 指定兼容的硬件版本
        vb.vmx["vmci0.version"] = "0"       # 禁用或降级 VMCI
    end

    node.vm.provision "shell", path: "scripts/common.sh"
    node.vm.provision "shell", path: "scripts/node.sh"
  end

  end
end
