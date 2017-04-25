# Add a repo for where we can get OVS 2.6 packages
#if [ ! -f /etc/yum.repos.d/delorean-deps.repo ] ; then
#    curl http://trunk.rdoproject.org/centos7/delorean-deps.repo | sudo tee /etc/yum.repos.d/delorean-deps.repo
#fi

# setup OVS master too
if [ ! -f /etc/yum.repos.d/ovsmaster.repo ] ; then
    curl https://copr.fedorainfracloud.org/coprs/leifmadsen/ovs-master/repo/epel-7/leifmadsen-ovs-master-epel-7.repo | sudo tee /etc/yum.repos.d/ovsmaster.repo
fi

sudo yum install -y
sudo yum remove -y firewalld

/vagrant/scripts/install-netperf.sh

sudo yum install -y --nogpgcheck  \
                    epel-release git git-review python-pip gcc python-devel \
                    openvswitch openvswitch-ovn-central openvswitch-ovn-host
sudo setenforce 0

# lookup my hostname IP from env
hostname=$(hostname)
ip=${!hostname}

echo hostname: $hostname, ip: $ip

for n in openvswitch ovn-controller ; do
    sudo systemctl enable $n
    sudo systemctl start $n
    systemctl status $n
done

# on gw1 we run ovn-northd

if [[ "$hostname" == "gw1" ]]; then
    cat | sudo tee /etc/sysconfig/ovn-northd <<EOF
OVN_NORTHD_OPTS="--db-sb-create-insecure-remote=yes --db-nb-create-insecure-remote=yes"
EOF
    sudo systemctl enable ovn-northd
    sudo systemctl start ovn-northd
    sudo systemctl status ovn-northd
fi

sudo ovs-vsctl set open . external-ids:ovn-remote=tcp:${gw1}:6642
sudo ovs-vsctl set open . external-ids:ovn-encap-type=geneve
sudo ovs-vsctl set open . external-ids:ovn-encap-ip=$ip

exit 0
