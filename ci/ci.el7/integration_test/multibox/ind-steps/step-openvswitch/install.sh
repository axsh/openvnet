#!/bin/bash

(
    $starting_step "Install Open vSwitch"
    run_cmd "rpm -qa | grep -wq openvswitch"
    $skip_step_if_already_done ; set -xe
    run_cmd "yum install -y openvswitch-2.4.1"
) ; prev_cmd_failed
