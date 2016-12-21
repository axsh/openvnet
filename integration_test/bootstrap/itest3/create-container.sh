#!/bin/bash

lxc-create -t centos -n vm5
chroot /var/lib/lxc/vm5/rootfs/ /bin/bash -c "echo \"root:\" | chpasswd"

lxc-create -t centos -n vm6
chroot /var/lib/lxc/vm6/rootfs/ /bin/bash -c "echo \"root:\" | chpasswd"
