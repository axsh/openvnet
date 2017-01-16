(
    $starting_step "Add mysql community release rpm package"
    sudo chroot ${TMP_ROOT} /bin/bash -c "rpm qa | grep -wq mysql-community-release-el7"
    $skip_step_if_already_done; set -ex
    sudo chroot ${TMP_ROOT} /bin/bash -c "wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm"
    sudo chroot ${TMP_ROOT} /bin/bash -c "rpm -ivh mysql-community-release-el7-5.noarch.rpm"
) ; prev_cmd_failed

(
    $starting_step "Install Mysql"
    sudo chroot ${TMP_ROOT} /bin/bash -c "rpm qe | grep -wq mysql-community-server-5.6.35-2.el7.x86_64"
    $skip_step_if_already_done; set -xe
    sudo chroot "${TMP_ROOT}" /bin/bash -ex <<EOS
         yum install -y mysql-server
EOS
) ; prev_cmd_failed
