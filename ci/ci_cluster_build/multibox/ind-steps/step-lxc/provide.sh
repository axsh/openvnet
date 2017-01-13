[[ -z ${#containers[@]} ]] || {
    for c in ${containers[@]} ; do
        (
            $starting_step "Start container: $c"
            run_ssh root@${IP_ADDR} "lxc-info -n $c | grep -q RUNNING"
            $skip_step_if_already_done; set -ex
            run_ssh root@${IP_ADDR} "lxc-start -n $c -d"
        ) ; prev_cmd_failed
    done
}
