(
    $starting_group "Install sclo ruby"
    sudo chroot ${TMP_ROOT} /bin/bash -c  "rpm -qa | grep -q rh-ruby"
    $skip_group_if_unessecarry
    (
        $starting_step "Install centos-release-scl"
        sudo chroot ${TMP_ROOT} /bin/bash -c  "rpm -qa | grep -qw centos-release-scl"
        $skip_step_if_already_done
        sudo chroot ${TMP_ROOT} /bin/bash -c "yum install -y centos-release-scl"
    ) ; prev_cmd_failed

    (
        $starting_step "Install yum-utils"
        sudo chroot ${TMP_ROOT} /bin/bash -c  "rpm -qa | grep -qw yum-utils"
        $skip_step_if_already_done
        sudo chroot ${TMP_ROOT} /bin/bash -c "yum install -y yum-utils"
    ) ; prev_cmd_failed

    (
        $starting_step "Enable RHSCL"
        sudo chroot ${TMP_ROOT} /bin/bash -c "which yum-config-manager > /dev/null"
        $skip_step_if_already_done
        sudo chroot ${TMP_ROOT} /bin/bash -c "yum-config-manager --enable rhel-server-rhscl-7-rpms"
    ) ; prev_cmd_failed

    (
        $starting_step "Install rh-ruby"
        sudo chroot ${TMP_ROOT} /bin/bash -c  "rpm -qa | grep -q rh-ruby"
        $skip_step_if_already_done
        sudo chroot ${TMP_ROOT} /bin/bash -c "yum install -y rh-ruby22"
    ) ; prev_cmd_failed
) ; prev_cmd_failed
