#!/bin/bash

lxc-create -t centos -n vm7
chroot /var/lib/lxc/vm7/rootfs/ /bin/bash -c "echo \"root:\" | chpasswd"
