#!/bin/sh

LOCAL_CONF=${1:-local.conf}
LOCAL_SH=$2

# configure ssh for no strict host checking (avoid making instalation interactive)
grep StrictHostKeyChecking ~/.ssh/config 2>/dev/null || \
    echo -e \"Host *\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config;
chmod 700 ~/.ssh/config;

# personalize git, etc, anything you use for development
[ -f /vagrant/personal_settings.sh ] && /vagrant/personal_settings.sh
source /etc/profile

git clone https://github.com/openstack-dev/devstack
cd devstack

# link the personal config, otherwise the example one (in git)
if [ -f /vagrant/$LOCAL_CONF ]; then
    ln -s /vagrant/$LOCAL_CONF local.conf
else
    ln -s /vagrant/local.conf.example local.conf
fi

if [ "x$LOCAL_SH" != "x" ]; then
    ln -s /vagrant/$LOCAL_SH local.sh
    chmod a+x /vagrant/$LOCAL_SH
fi

./unstack.sh
./stack.sh
