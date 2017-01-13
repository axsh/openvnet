#!/bin/bash

(
    $starting_step "Install Redis"
    [[ -f ${TMP_ROOT}/etc/init.d/redis ]]
    $skip_step_if_already_done; set -xe
    sudo chroot "${TMP_ROOT}" /bin/bash -c \
         "yum install -y redis"
) ; prev_cmd_failed
