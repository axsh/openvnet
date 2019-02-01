
(
    $starting_step "Update openvnet repository"
    false # Always perform this step
    $skip_step_if_already_done; set -ex
    run_cmd <<EOF
cat <<EOS > /etc/yum.repos.d/openvnet.repo
[openvnet]
name=OpenVNet
failovermethod=priority
baseurl=https://ci.openvnet.org/repos/${BRANCH}/packages/rhel/7/vnet/${RELEASE_SUFFIX:-current}
enabled=1
gpgcheck=0
EOS
EOF

) ; prev_cmd_failed

(
    $starting_step "Install OpenVNet"
    run_cmd "rpm -qa | grep -wq openvnet"
    $skip_step_if_already_done ; set -xe
    run_cmd "yum install -y openvnet"
) ; prev_cmd_failed
