
for node in ${scheduled_nodes[@]} ; do
    [[ $node != "base" ]] && {
        (
            $starting_step "Copy base raw image"
            can_skip=true
            [[ -f "${ENV_ROOTDIR}/${node}/box-disk1.raw" ]] && can_skip=true
            [[ ${REBUILD} == "false" && -f "${CACHE_DIR}/${BRANCH}/${vm_name}.qcow2" ]] && can_skip=true
            $can_skip
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
