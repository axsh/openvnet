(
    # Needed for ifconfig which is used by the net-dhcp gem in openvnet
    $starting_step "Install Net-tools"
    run_cmd "which ifconfig" > /dev/null
    $skip_step_if_already_done ; set -xe
    run_cmd "yum install -y net-tools tcpdump"
) ; prev_cmd_failed
