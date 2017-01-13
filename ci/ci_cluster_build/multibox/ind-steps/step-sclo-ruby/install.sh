(
    $starting_group "Install sclo ruby"

    $skip_group_if_unessecarry
    (
        $starting_step "Install centos-release-scl"
        false
        $skip_step_if_already_done
        sudo chroot ${TMP_ROOT} /bin/bash -c "yum install -y centos-release-scl"
    ) ; prev_cmd_failed

    (
        $starting_step "Install yum-utils"
        false
        $skip_step_if_already_done
        sudo chroot ${TMP_ROOT} /bin/bash -c "yum install -y yum-utils"
    ) ; prev_cmd_failed

    (
        $starting_step "Enable RHSCL"
        false
        $skip_step_if_already_done
        sudo chroot ${TMP_ROOT} /bin/bash -c "yum-config-manager --enable rhel-server-rhscl-7-rpms"
    ) ; prev_cmd_failed

    (
        $starting_step "Install rh-ruby"
        false
        $skip_step_if_already_done
        sudo chroot ${TMP_ROOT} /bin/bash -c "yum install -y rh-ruby22"
    ) ; prev_cmd_failed
) ; prev_cmd_failed
