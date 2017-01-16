(
    $starting_step "Install Open vSwitch"
    run_ssh root@${IP_ADDR} "rpm -qa | grep -wq openvswitch"
    $skip_step_if_already_done ; set -xe
    run_ssh root@${IP_ADDR} "yum install -y openvswitch"
) ; prev_cmd_failed
