#!/bin/bash

(
    $starting_step "Install LXC"
    [[ -f ${TMP_ROOT}/usr/bin/lxc-create && -f ${TMP_ROOT}/usr/bin/lxc-ls ]]
    $skip_step_if_already_done; set -xe
    sudo chroot "${TMP_ROOT}" /bin/bash -c \
         "yum install -y lxc lxc-extra lxc-templates lxc-devel debootstrap"
) ; prev_cmd_failed

[[ $base == "true" ]] && {
    (
        $starting_group "Download centos system used by containers"
        release_ver=$(sudo chroot ${TMP_ROOT} /bin/bash -c "rpm -q --queryformat '%{VERSION}' centos-release")
        sudo chroot ${TMP_ROOT} /bin/bash -c "[ -d /var/cache/lxc/centos/x86_64/${release_ver}/rootfs ]"
        $skip_group_if_unnecessary
        (
            $starting_step "Create a centos container"
            sudo chroot ${TMP_ROOT} /bin/bash -c "lxc-info -n init" &> /dev/null
            [[ $? == 0 ]]
            $skip_step_if_already_done; set -xe
            sudo chroot "${TMP_ROOT}" /bin/bash -c \
                 "lxc-create -n init -t centos"
        ) ; prev_cmd_failed
        
        (
            $starting_step "Delete test container"
            sudo chroot ${TMP_ROOT} /bin/bash -c "lxc-info -n init" &> /dev/null
            [[ $? == 1 ]]
            $skip_step_if_already_done; set -xe
            sudo chroot "${TMP_ROOT}" /bin/bash -c \
                 "lxc-destroy -n init"
        ) ; prev_cmd_failed
    ) ; prev_cmd_failed
} || {
    [[ -z ${#containers[@]} ]] || {
        for c in ${containers[@]} ; do
            (
                $starting_step "Create container: $c"
                sudo chroot ${TMP_ROOT} /bin/bash -c "lxc-info -n $c" &> /dev/null
                [[ $? == 0 ]]
                $skip_step_if_already_done; set -ex
                sudo chroot "${TMP_ROOT}" /bin/bash -c \
                     "lxc-create -n $c -t centos"

                create_config ${c}
                install_ssh ${c}
            ) ; prev_cmd_failed
        done
    }
}
