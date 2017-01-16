(
    $starting_group "Install OpenVNet"
    run_ssh root@${IP_ADDR} "rpm -qa | grep -wq openvnet"
    $skip_group_if_unnecessary

    build "openvswitch"

    (
        $starting_step "Install OpenVNet"
        run_ssh root@${IP_ADDR} "rpm -qa | grep -wq openvnet"
        $skip_step_if_already_done ; set -xe
        run_ssh root@${IP_ADDR} "yum install -y openvnet"
    ) ; prev_cmd_failed
)
