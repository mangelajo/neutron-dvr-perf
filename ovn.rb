Vagrant.require_plugin "vagrant-reload"

def provision_ovn(config, script, env: nil)
    config.vm.provision :shell, privileged:true, path: '../scripts/rhel-ovn.sh',
                        env:env
    config.vm.provision :reload
    # exec the local.sh separately
    if script != nil then
        config.vm.provision :shell do |shell|
            shell.privileged = true
            shell.path = '../scripts/' + script
            shell.env = env
        end
    end
end
