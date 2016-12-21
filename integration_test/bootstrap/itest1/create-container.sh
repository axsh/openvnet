#!/bin/bash

lxc-create -t centos -n vm1
chroot /var/lib/lxc/vm1/rootfs/ /bin/bash -c "echo \"root:\" | chpasswd"

lxc-create -t centos -n vm2
chroot /var/lib/lxc/vm2/rootfs/ /bin/bash -c "echo \"root:\" | chpasswd"
