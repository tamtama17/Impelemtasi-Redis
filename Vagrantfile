Vagrant.configure("2") do |config|
  config.vm.define "rmaster" do |node|
    node.vm.box = "bento/ubuntu-16.04"
    node.vm.hostname = "rmaster"
    node.vm.network "private_network", ip: "192.168.200.100"

    node.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.name = "rmaster"
      vb.memory = "2048"
    end
  end
  (1..2).each do |i|
    config.vm.define "rslave#{i}" do |node|
      node.vm.box = "bento/ubuntu-16.04"
      node.vm.hostname = "rslave#{i}"
      node.vm.network "private_network", ip: "192.168.200.10#{i}"

      node.vm.provider "virtualbox" do |vb|
        vb.gui = false
        vb.name = "rslave#{i}"
        vb.memory = "1024"
      end
    end
  end
end
