(
    $starting_step "Unbind redis from localhost only"
    sudo grep -q "^#bind" ${TMP_ROOT}/etc/redis.conf
    $skip_step_if_already_done; set -xe
    sudo chroot "${TMP_ROOT}" /bin/bash -c \
         "sed -i 's/bind/#bind/g' /etc/redis.conf"
) ; prev_cmd_failed
