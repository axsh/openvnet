#!/bin/bash

(
    $starting_step "Unbind redis from localhost only"
    sudo grep -q "^#bind" ${TMP_ROOT}/etc/redis.conf
    $skip_step_if_already_done; set -xe
    run_cmd "sed -i 's,bind,#bind,g' /etc/redis.conf"
) ; prev_cmd_failed
