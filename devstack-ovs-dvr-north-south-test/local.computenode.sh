#!/bin/sh

echo local.sh executed
echo primary: $primary
echo subnode1: $subnode1

source ~/devstack/openrc admin admin

ID_DMZ_NET=$(neutron net-show dmz | awk ' / id / { print $4 }')
ID_INSIDE_NET=$(neutron net-show inside | awk '/ id / { print $4 }')

DMZ_VM2_MAC=$(neutron port-show dmz-vm2 | awk ' / mac_address / { print $4 } ')
DMZ_VM2_ID=$(neutron port-show dmz-vm2 | awk ' / id / { print $4 } ')
DMZ_VM2_SGID=$(neutron port-show dmz-vm2 | awk ' / security_groups / { print $4 } ')
INSIDE_VM4_MAC=$(neutron port-show inside-vm4 | awk ' / mac_address / { print $4 } ')
INSIDE_VM4_ID=$(neutron port-show inside-vm4 | awk ' / id / { print $4 } ')


sudo ip netns add vm2
sudo ovs-vsctl -- --may-exist add-port br-int vm2 \
               -- set Interface vm2 type=internal  \
               external_ids:attached-mac=$DMZ_VM2_MAC \
               external_ids:iface-id=$DMZ_VM2_ID \
               external_ids:vm-id=vm-$DMZ_VM2_ID \
               external_ids:iface-status=active external_ids:owner=admin \
               other_config:tag=1

sudo ip link set vm2 address $DMZ_VM2_MAC

sudo ip link set vm2 netns vm2
sudo ip netns exec vm2 ip link set dev vm2 up
sudo ip netns exec vm2 dhclient -I vm2 --no-pid vm2
sudo ip netns exec vm2 ip addr show


sudo ip netns add vm4
sudo ovs-vsctl -- --may-exist add-port br-int vm4 \
               -- set Interface vm4 type=internal  \
               external_ids:attached-mac=$INSIDE_VM4_MAC \
               external_ids:iface-id=$INSIDE_VM4_ID \
               external_ids:vm-id=vm-$INSIDE_VM4_ID \
               external_ids:iface-status=active external_ids:owner=admin \
               other_config:tag=1


sudo ip link set vm4 address $INSIDE_VM4_MAC

sudo ip link set vm4 netns vm4
sudo ip netns exec vm4 ip link set dev vm4 up
sudo ip netns exec vm4 dhclient -I vm4 --no-pid vm4
sudo ip netns exec vm4 ip addr show
sudo ip netns exec vm4 ip route show


FIP_ID=$(neutron floatingip-create public | awk '/ id / { print $4 }')
FIP_IP=$(neutron floatingip-show $FIP_ID  | awk '/ floating_ip_address / { print $4 }')
neutron floatingip-associate $FIP_ID $DMZ_VM2_ID
sleep 5
sudo ping $FIP_IP -i 0.01 -c 1000
