
(
    $starting_step "Install Mysql"
    [[ -f ${TMP_ROOT}/etc/init.d/mysqld ]]
    $skip_step_if_already_done; set -xe
    sudo chroot "${TMP_ROOT}" /bin/bash -ex <<EOS
         yum install -y mysql-server
EOS
) ; prev_cmd_failed
