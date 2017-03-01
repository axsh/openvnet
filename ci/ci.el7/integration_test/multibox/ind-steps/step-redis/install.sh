#!/bin/bash

(
    $starting_step "Install Redis"
    [[ -f ${TMP_ROOT}/etc/init.d/redis ]]
    $skip_step_if_already_done; set -xe
    run_cmd "yum install -y redis"
) ; prev_cmd_failed
