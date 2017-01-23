(
    $starting_step "Add mysql community release rpm package"
    run_cmd "rpm -qa | grep -wq mysql-community-release-el7"
    $skip_step_if_already_done; set -ex
    run_cmd "curl -O http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm"
    run_cmd "rpm -ivh mysql-community-release-el7-5.noarch.rpm"
) ; prev_cmd_failed

(
    $starting_step "Install Mysql"
    run_cmd "rpm qe | grep -wq mysql-community-server-5.6.35-2.el7.x86_64"
    $skip_step_if_already_done; set -xe
    run_cmd "yum install -y mysql-server"
) ; prev_cmd_failed
