#!/bin/sh

HOSTS="gw1 gw2 hv1 hv2"
GIT_REMOTE=${GIT_REMOTE:-mangelajo}
GIT_BRANCH=${GIT_BRANCH:-l3ha}
for host in $HOSTS; do
     vagrant ssh $host -c "sudo chown vagrant:vagrant -R ovs && \
                           cd ovs && \
                           git fetch -a $GIT_REMOTE && \
                           git checkout remotes/$GIT_REMOTE/$GIT_BRANCH && \
                           make -j5 && \
                           sudo make install &&
                           sudo systemctl restart ovn-controller"
 done

 vagrant ssh gw1 -c "sudo systemctl restart ovn-northd"
