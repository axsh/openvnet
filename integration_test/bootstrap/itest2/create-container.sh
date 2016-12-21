#!/bin/bash

lxc-create -t centos -n vm3
chroot /var/lib/lxc/vm3/rootfs/ /bin/bash -c "echo \"root:\" | chpasswd"

lxc-create -t centos -n vm4
chroot /var/lib/lxc/vm4/rootfs/ /bin/bash -c "echo \"root:\" | chpasswd"
