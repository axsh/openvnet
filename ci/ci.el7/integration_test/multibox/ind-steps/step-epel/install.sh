#!/bin/bash

(
    $starting_step "Install EPEL"
    run_cmd "rpm -qa epel-release* | egrep -q epel-release"
    [[ $? -eq 0 ]]
    $skip_step_if_already_done; set -xe
    run_cmd "yum install -y epel-release"

) ; prev_cmd_failed
