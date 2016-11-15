#!/bin/sh

echo local.compute.sh executed!
echo primary: $primary
echo subnode1: $subnode1

sudo bash << EOF

set -x

ip netns add vm2
ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
ip link set vm2 address 02:ac:10:ff:01:31
ip link set vm2 netns vm2
ovs-vsctl set Interface vm2 external_ids:iface-id=dmz-vm2
ip netns exec vm2 dhclient -I vm2 --no-pid vm2
ip netns exec vm2 ip addr show vm2
ip netns exec vm2 ip route show

ip netns add vm4
ovs-vsctl add-port br-int vm4 -- set interface vm4 type=internal
ip link set vm4 address 02:ac:10:ff:01:95
ip link set vm4 netns vm4
ovs-vsctl set Interface vm4 external_ids:iface-id=inside-vm4
ip netns exec vm4 dhclient -I vm4 --no-pid vm4
ip netns exec vm4 ip addr show vm4
ip netns exec vm4 ip route show

EOF
