
(
    $starting_step "Install OpenVNet"
    run_cmd "rpm -qa | grep -wq openvnet"
    $skip_step_if_already_done ; set -xe
    run_cmd "yum install -y openvnet"
) ; prev_cmd_failed
