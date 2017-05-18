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
sudo yum update -y kernel # fetch latest kernel
sudo yum install -y --nogpgcheck  \
                    epel-release git git-review python-pip gcc python-devel \
                    openvswitch openvswitch-ovn-central openvswitch-ovn-host \
                    make autoconf openssl-devel automake python-devel \
                    kernel-devel graphviz kernel-debug-devel rpm-build \
                    redhat-rpm-config libtool checkpolicy selinux-policy-devel \
                    python-six vim


sudo setenforce 0

GIT_REPO=${GIT_REPO:-https://github.com/mangelajo/ovs}
GIT_BRANCH=${GIT_BRANCH:-l3ha}

git clone $GIT_REPO
cd ovs

git remote add mangelajo https://github.com/mangelajo/ovs
git remote add anil  https://github.com/venkataanil/ovs
git remote add upstream https://github.com/openvswitch/ovs

if [[ "z$GIT_BRANCH" != "z" ]]; then
    git checkout $GIT_BRANCH
fi

./boot.sh
CFLAGS="-O0 -g" ./configure --prefix=/ --with-linux=/usr/lib/modules/`ls /usr/lib/modules/ | tail -n 1`/build
make -j5 V=0 install
sudo make install
cd datapath/linux
make all
make modules_install

# lookup my hostname IP from env
hostname=$(hostname)
ip=${!hostname}

echo hostname: $hostname, ip: $ip

for n in openvswitch ovn-controller ; do
    sudo systemctl enable $n
    sudo systemctl start $n
    systemctl status $n
done

#
# on gw1 we run the ovn-northd controller
#
if [[ "$hostname" == "gw1" ]]; then
    cat | sudo tee /etc/sysconfig/ovn-northd <<EOF
OVN_NORTHD_OPTS="--db-sb-create-insecure-remote=yes --db-nb-create-insecure-remote=yes"
EOF
    sudo systemctl enable ovn-northd
    sudo systemctl start ovn-northd
    sudo systemctl status ovn-northd
fi


exit 0
