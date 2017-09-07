# -*- mode: ruby -*-
# vi: set ft=ruby :
# Fail if the version of Vagrant is pre 1.8 (when Ansible local was added)
Vagrant.require_version '>= 1.8'

require 'ipaddr'
require 'pathname'
require 'yaml'

ruby_min_version = Gem::Version.new('2.2.1')

abort "Ruby should be >= #{ruby_min_version.to_s}" unless Gem::Version.new(RUBY_VERSION) >= ruby_min_version

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  required_plugins = %w(
    vagrant-hostmanager
    vagrant-triggers
    vagrant-bindfs
    vagrant-vmware-fusion
    vagrant-parallels
    vagrant-cachier
  )

  plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
  if not plugins_to_install.empty?
    puts "Installing plugins: #{plugins_to_install.join(' ')}"
    if system "vagrant plugin install #{plugins_to_install.join(' ')}"
      exec "vagrant #{ARGV.join(' ')}"
    else
      abort 'Installation of one or more plugins has failed. Aborting.'
    end
  end

  config.vm.box = 'bento/ubuntu-16.04'

  config.vm.define :shrikeh

  config.hostmanager.enabled            = true
  config.hostmanager.manage_host        = true
  config.hostmanager.manage_guest       = true
  config.hostmanager.ignore_private_ip  = false
  config.hostmanager.include_offline    = true

  config.hostmanager.aliases  = %w(
    dev.local
    shrikeh.local
  )

  # Get the dynamic hostname from the running box so we know what to put in
  # /etc/hosts even though we don't specify a static private ip address
  $logger = Log4r::Logger.new('vagrantfile')

  def read_ip_address(machine)
    command =  "ip a | grep 'inet' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $2 }' | cut -f1 -d\"/\""
    result  = ''

    $logger.info "Processing #{ machine.name } ... "

    begin
      # sudo is needed for ifconfig
      machine.communicate.sudo(command) do |type, data|
        result << data if type == :stdout
      end
      $logger.info "Processing #{ machine.name } ... success"
    rescue
      result = "# NOT-UP"
      $logger.info "Processing #{ machine.name } ... not running"
    end

    return result.chomp.split("\n").last
  end

  config.hostmanager.ip_resolver = proc do |vm, _|
    if vm.communicate.ready?
      read_ip_address(vm)
    end
  end

  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.
  #my_conf = YAML.load_file('config.yaml')

  # Sometimes there are issues with dns setup on vmware/virtualbox, so we force resolution
  dns_server = IPAddr.new '8.8.8.8'
  config.vm.provision :dns,
    type:   :shell,
    inline: "echo nameserver #{dns_server.to_s} > /etc/resolv.conf;"

  config.vm.network :private_network, type: :dhcp

  # Set up port forwarding for using MySQL from the host
  config.vm.network :forwarded_port,
    guest:        3306,
    host:         33609,
    auto_correct: true

  vmname              = 'shrikeh'
  config.cache.scope  = :box
  config.vm.hostname  = vmname

  config.ssh.forward_agent = true

  config.vm.synced_folder '.', '/vagrant',
    disabled: true

  config.vm.synced_folder './code', '/code',
    type: :nfs,
    create: true



  config.vm.synced_folder './.ssh-keys', '/root/.ssh',
    id:     'ssh',
    type:   :nfs,
    create: true

  # If the user has VMWare locally, this will be faster than parallels
  %w(vmware_workstation, vmware_fusion).each do |vmware_provider|
    config.vm.provider(vmware_provider) do |vmw, override|
      override.vm.box = 'hashicorp/precise64'
    end
  end

  # But also set up parallels if no VMWare present
  config.vm.provider :parallels do |prl, override|
    prl.name        = vmname
    prl.memory      = 2048
    prl.cpus        = 1
  end

  virtualenv_dir = '.venv'
  provision_ansible = 'provisioning/setup.sh'
  config.trigger.before :up do
    run "chmod +x #{provision_ansible}"
    run "#{provision_ansible}"
  end

  config.vm.provision :ansible do |ansible|
    ansible.playbook          = 'provisioning/ansible/playbook.yml'
    #ansible.galaxy_role_file  = 'ansible/galaxy.yml'
    ansible.sudo              = true
    # ansible.extra_vars = {
    #   github_oauth:     my_conf['github_oauth']
    # }
  end
end
