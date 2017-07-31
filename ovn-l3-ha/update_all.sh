#!/bin/sh

HOSTS="gw1 gw2 hv1 hv2 ctl"
GIT_REMOTE=${GIT_REMOTE:-mangelajo}
GIT_BRANCH=${GIT_BRANCH:-l3ha-v4}
for host in $HOSTS; do
     vagrant ssh $host -c "sudo chown vagrant:vagrant -R ovs && \
                           cd ovs && \
                           git fetch -a $GIT_REMOTE && \
                           git checkout remotes/$GIT_REMOTE/$GIT_BRANCH && \
                           make -j5 && \
                           sudo make install" || exit 1
    if [[ "$host" != "ctl" ]]; then
      vagrant ssh $host -c "sudo systemctl restart ovn-controller" || exit 2
    fi

 done

 vagrant ssh ctl -c "sudo systemctl restart ovn-northd"
