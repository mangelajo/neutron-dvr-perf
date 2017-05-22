#!/bin/sh

echo local.sh executed
echo primary: $primary
echo subnode1: $subnode1

export MYSQL_PASSWORD=password
cd /opt/stack/neutron/tools
./configure_for_func_testing.sh /home/vagrant/devstack -i
cd ..
tox -e dsvm-fullstack
