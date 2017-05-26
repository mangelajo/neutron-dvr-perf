def provision_devstack(config, local_conf:'local.conf', local_sh: nil, env: nil)
    config.vm.provision :shell, privileged:true, path: '../lib/scripts/rhel-devstack.sh'
    config.vm.provision :shell do |shell|
        shell.privileged = false
        shell.path = '../lib/scripts/devstack.sh'
        shell.args = [ local_conf ]
    end
    # exec the local.sh separately
    if local_sh != nil then
        config.vm.provision :shell do |shell|
            shell.privileged = false
            shell.path = local_sh
            shell.env = env
        end
    end
end
