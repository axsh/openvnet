(
    $starting_step "Install OpenVNet"
    rpm -qa | grep -wq openvnet
    $skip_step_if_already_done ; set -xe
    sudo chroot "${TMP_ROOT}" /bin/bash -c "yum install -y openvnet"
) ; prev_cmd_failed
