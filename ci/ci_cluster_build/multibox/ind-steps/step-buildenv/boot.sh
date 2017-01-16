
for node in ${scheduled_nodes[@]} ; do
    [[ $node != "base" && $REBUILD == "true" ]] && {
        (
            $starting_step "Copy base raw image"
            [[ -f "${ENV_ROOTDIR}/${node}/box-disk1.raw" ]]
            $skip_step_if_already_done; set -ex
            cp "${ENV_ROOTDIR}/base/box-disk1.raw" "${ENV_ROOTDIR}/${node}/"
        ) ; prev_cmd_failed
    }

    (
        $starting_group "Building ${node%,*}"
        false
        $skip_group_if_unnecessary
        "${ENV_ROOTDIR}/${node}/build.sh"
    ) ; prev_cmd_failed
done
