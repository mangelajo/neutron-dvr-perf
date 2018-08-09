sudo yum install -y https://www.rdoproject.org/repos/rdo-release.rpm
sudo yum update -y

sudo yum install -y epel-release git git-review python-pip gcc python-devel
sudo yum remove -y firewalld
sudo pip install --upgrade pip
sudo yum remove -y python-setuptools
sudo yum install -y python-setuptools
sudo pip install psutil

/vagrant/install-netperf.sh

exit 0
