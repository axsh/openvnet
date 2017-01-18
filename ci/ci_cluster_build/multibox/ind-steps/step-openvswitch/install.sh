(
    $starting_step "Install Open vSwitch"
    sudo chroot ${TMP_ROOT} /bin/bash -c "rpm -qa | grep -wq openvswitch"
    $skip_step_if_already_done ; set -xe
    sudo chroot ${TMP_ROOT} /bin/bash -c "yum install -y openvswitch-2.4.1"
) ; prev_cmd_failed
