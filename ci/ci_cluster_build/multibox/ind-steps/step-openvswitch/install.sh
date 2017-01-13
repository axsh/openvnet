(
    $starting_step "Install Open vSwitch"
    rpm -qa | grep -wq openvswitch
    $skip_step_if_already_done ; set -xe
    sudo chroot "${TMP_ROOT}" /bin/bash -c "yum install -y openvswitch"
) ; prev_cmd_failed
