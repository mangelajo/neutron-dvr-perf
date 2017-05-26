sudo yum install -y epel-release git git-review python-pip gcc python-devel
sudo yum remove -y firewalld
sudo pip install --upgrade pip

/vagrant/install-netperf.sh

exit 0
