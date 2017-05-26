Vagrant.require_plugin "vagrant-reload"

def provision_ovn(config, script, env: nil)
    config.vm.provision :shell, privileged:true, path: '../lib/scripts/rhel-ovn.sh',
                        env:env
    config.vm.provision :reload
    # exec the local.sh separately

    if ENV.has_key? 'GIT_BRANCH' then
        env['GIT_BRANCH'] = ENV['GIT_BRANCH']
    end

    if ENV.has_key? 'GIT_REPO' then
        env['GIT_REPO'] = ENV['GIT_REPO']
    end

    if script != nil then
        config.vm.provision :shell do |shell|
            shell.privileged = true
            shell.path = script
            shell.env = env
        end
    end
end
