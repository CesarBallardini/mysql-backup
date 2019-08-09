# -*- mode: ruby -*-
# vi: set ft=ruby :

# descarga box y crea VM
# agrega un segundo disco en el mismo directorio que usa VB para la vm
# formatea segundo disco con LVM
# agrega un sync folder /vagrant/

extra_disk_size_mb = 500

Vagrant.configure("2") do |config|
  config.vm.box = "debian/buster64"

  # config.vm.box_check_update = false

  # config.vm.network "forwarded_port", guest: 80, host: 8080
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
  # config.vm.network "private_network", ip: "192.168.33.10"
  # config.vm.network "public_network"
  # config.vm.synced_folder "../data", "/vagrant_data"


  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false
 
    # Customize the amount of memory on the VM:
    vb.memory = "1024"

    vb.name = "mysql"

    config.vm.synced_folder ".", "/vagrant" , type: "virtualbox"

    # Get disk path
    line = `LANG=C VBoxManage list systemproperties | grep "Default machine folder"`
    vb_machine_folder = line.split(':')[1].strip()
    extra_disk_filename = File.join(vb_machine_folder, vb.name.to_s, 'disk2.vdi')

    # agrega un segundo disco
    unless File.exist?(extra_disk_filename)
      vb.customize ['createhd', '--filename', extra_disk_filename, '--size', extra_disk_size_mb] # size is in MB
    end
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', extra_disk_filename]

  end

  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end
