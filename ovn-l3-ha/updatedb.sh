#!/bin/sh

sudo service ovn-northd stop
for what in nb sb; do
    sudo cp /home/vagrant/ovs/ovn/ovn-${what}.ovsschema /usr/share/openvswitch/
    sudo ovsdb-tool convert /var/lib/openvswitch/ovn${what}_db.db \
                            /home/vagrant/ovs/ovn/ovn-${what}.ovsschema
done

