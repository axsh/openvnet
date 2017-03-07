#!/bin/bash

(
    $starting_step "Install EPEL"
    run_cmd "rpm -qa epel-release* | egrep -q epel-release"
    [[ $? -eq 0 ]]
    $skip_step_if_already_done; set -xe
    run_cmd "rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm"

) ; prev_cmd_failed
