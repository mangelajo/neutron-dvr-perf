Instructions
============

.. code-block:: bash

    git checkout https://github.com/mangelajo/vagrants
    cd vagrants/ovn-l3-ha
    vagrant up
    vagrant ssh hv1 -c "ping 10.0.0.111"


you can specify a git repo or branch if you want:

.. code-block:: bash

    GIT_REPO=https://github.com/mangelajo/ovs GIT_BRANCH=l3ha vagrant up


those are the defaults btw.
