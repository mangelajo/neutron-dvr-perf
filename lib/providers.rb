def configure_providers(vm, os:nil, ram:nil, vcpus:nil)

    boxes = {:virtualbox => {'trusty64' => 'ubuntu/trusty64',
                             'centos7'  => 'centos/7'},
             :libvirt    => {'trusty64' => 'celebdor/trusty64',
                             'centos7'  => 'centos/7'},
             :parallels  => {'trusty64' => 'parallels/trusty64',
                             'centos7'  => 'parallels/centos-7.0'}}

    vm_memory = ENV['VM_MEMORY'] || ram || '6000'
    vm_cpus = ENV['VM_CPUS'] || vcpus || '1'
    vm_os = ENV['VM_OS'] || os || 'centos7'

    vm.provider 'virtualbox' do |vb, config|
        config.vm.box = boxes[:virtualbox][vm_os]
        vb.gui = true
        vb.memory = vm_memory
        vb.cpus = vm_cpus
    end

    vm.provider 'libvirt' do |lb, config|
        config.vm.box = boxes[:libvirt][vm_os]
        config.vm.synced_folder './', '/vagrant', type: 'rsync'
        lb.nested = true
        lb.memory = vm_memory
        lb.cpus = vm_cpus
        lb.suspend_mode = 'managedsave'
    end

    vm.provider 'parallels' do |p, config|
        config.vm.box = boxes[:parallels][vm_os] 
        p.memory = vm_memory
        p.cpus = vm_cpus
    end

    vm.provider 'openstack' do |os, config|
        os.server_name        = 'devstack'
        os.openstack_auth_url = "#{ENV['OS_AUTH_URL']}/tokens"
        os.username           = "#{ENV['OS_USERNAME']}"
        os.password           = "#{ENV['OS_PASSWORD']}"
        os.tenant_name        = "#{ENV['OS_TENANT_NAME']}"
        #TODO(map ram/os settings to flavors)
        os.flavor             = ['oslab.4cpu.20hd.8gb', 'm1.large']
        os.image              = ['centos7', 'centos-7-cloud']
        os.floating_ip_pool   = ['external', 'external-compute01']
        os.user_data          = <<-EOF
#!/bin/bash
sed -i 's/Defaults    requiretty/Defaults    !requiretty/g' /etc/sudoers
      EOF
      config.ssh.username = 'centos'
    end
end
