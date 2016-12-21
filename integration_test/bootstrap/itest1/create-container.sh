#!/bin/bash

containers=(
    vm1
    vm2
)

for c in ${containers[@]} ; do
    lxc-create -t centos -n ${c}
    chroot /var/lib/lxc/${c}/rootfs/ /bin/bash -c "echo root: | chpasswd"

    sed -i \
        -e 's,^PermitRootLogin .*,PermitRootLogin yes,' \
        -e 's,^PasswordAuthentication .*,PasswordAuthentication no,' \
        -e 's,^GSSAPIAuthentication .*, GSSAPIAuthentication no,' \
        -e 's,^#PubkeyAuthentication .*, PubkeyAuthentication yes,' \
        \
        /var/lib/lxc/${c}/rootfs/etc/ssh/sshd_config
done
