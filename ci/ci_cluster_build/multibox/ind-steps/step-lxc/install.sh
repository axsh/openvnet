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
        $starting_group "Download tarball used by containers"
        # TODO: check if tarball exists
        false
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
            ) ; prev_cmd_failed
        done
    }
}
