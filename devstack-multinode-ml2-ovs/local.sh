#!/bin/sh

echo local.sh executed
echo primary: $primary
echo subnode1: $subnode1

source ~/devstack/openrc admin admin

neutron net-create dmz
neutron net-create inside

# we use --disable-dhcp first to make sure dhcp server does not take addresses we want
ID_DMZ=$(neutron subnet-create dmz --name dmz_subnet 172.16.255.128/26 --disable-dhcp| awk '/ id / { print  $4 }')
ID_INSIDE=$(neutron subnet-create inside --name inside_subnet 172.16.255.192/26 --disable-dhcp| awk '/ id / { print  $4 }')

neutron port-create --device-owner compute:container --name dmz-vm1 \
                    dmz \
                    --fixed-ip subnet_id=$ID_DMZ,ip_address=172.16.255.130 \
                    --binding:host_id=$(hostname)

neutron port-create --device-owner compute:container --name dmz-vm2 \
                    dmz \
                    --fixed-ip subnet_id=$ID_DMZ,ip_address=172.16.255.131 \
                    --binding:host_id=subnode1

neutron port-create --device-owner compute:container --name inside-vm3 \
                    inside \
                    --fixed-ip subnet_id=$ID_INSIDE,ip_address=172.16.255.194 \
                    --binding:host_id=$(hostname)

neutron port-create --device-owner compute:container --name inside-vm4 \
                    inside \
                    --fixed-ip subnet_id=$ID_INSIDE,ip_address=172.16.255.195 \
                    --binding:host_id=subnode1


# now we let DHCP agent take any port it wishes

neutron subnet-update dmz_subnet --enable-dhcp
neutron subnet-update inside_subnet --enable-dhcp

ID_DMZ_NET=$(neutron net-show dmz | awk ' / id / { print $4 }')
ID_INSIDE_NET=$(neutron net-show inside | awk '/ id / { print $4 }')

DMZ_VM1_MAC=$(neutron port-show dmz-vm1 | awk ' / mac_address / { print $4 } ')
DMZ_VM1_ID=$(neutron port-show dmz-vm1 | awk ' / id / { print $4 } ')
DMZ_VM1_SGID=$(neutron port-show dmz-vm1 | awk ' / security_groups / { print $4 } ')
INSIDE_VM3_MAC=$(neutron port-show inside-vm3 | awk ' / mac_address / { print $4 } ')
INSIDE_VM3_ID=$(neutron port-show inside-vm3 | awk ' / id / { print $4 } ')


sudo ip netns add vm1
sudo ovs-vsctl -- --may-exist add-port br-int vm1 \
               -- set Interface vm1 type=internal  \
               external_ids:attached-mac=$DMZ_VM1_MAC \
               external_ids:iface-id=$DMZ_VM1_ID \
               external_ids:vm-id=vm-$DMZ_VM1_ID \
               external_ids:iface-status=active external_ids:owner=admin \
               other_config:tag=1

sudo ip link set vm1 address $DMZ_VM1_MAC

sudo ip link set vm1 netns vm1
sudo ip netns exec vm1 ip link set dev vm1 up
sudo ip netns exec vm1 dhclient -I vm1 --no-pid vm1
sudo ip netns exec vm1 ip addr show
sudo ip netns exec vm1 ip route show



sudo ip netns add vm3
sudo ovs-vsctl -- --may-exist add-port br-int vm3 \
               -- set Interface vm3 type=internal  \
               external_ids:attached-mac=$INSIDE_VM3_MAC \
               external_ids:iface-id=$INSIDE_VM3_ID \
               external_ids:vm-id=vm-$INSIDE_VM3_ID \
               external_ids:iface-status=active external_ids:owner=admin \
               other_config:tag=1 # the tag thing is a workaround to avoid 4095 vlan

sudo ip link set vm3 address $INSIDE_VM3_MAC

sudo ip link set vm3 netns vm3
sudo ip netns exec vm3 ip link set dev vm3 up
sudo ip netns exec vm3 dhclient -I vm3 --no-pid vm3
sudo ip netns exec vm3 ip addr show
sudo ip netns exec vm3 ip route show


neutron router-create router_dmz
neutron router-gateway-set router_dmz public
neutron router-interface-add router_dmz dmz_subnet
neutron router-interface-add router_dmz inside_subnet


neutron security-group-rule-create $DMZ_VM1_SGID --direction ingress

FIP_ID=$(neutron floatingip-create public | awk '/ id / { print $4 }')
FIP_IP=$(neutron floatingip-show $FIP_ID  | awk '/ floating_ip_address / { print $4 }')
neutron floatingip-associate $FIP_ID $DMZ_VM1_ID
sleep 5
sudo ping $FIP_IP -i 0.01 -c 1000
