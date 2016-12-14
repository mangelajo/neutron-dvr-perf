cd /tmp
wget -c ftp://ftp.netperf.org/netperf/netperf-2.7.0.tar.bz2
tar xvfj netperf-2.7.0.tar.bz2
cd netperf-2.7.0
./configure --prefix=/usr
sudo make install

