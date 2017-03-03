
for node in ${scheduled_nodes[@]} ; do
    (
        $starting_group "Building ${node%,*}"
        false
        $skip_group_if_unnecessary
        [[ "${node}" == "base" && -f "${CACHE_DIR}/${BRANCH}/box-disk1.raw" ]] && continue
        "${ENV_ROOTDIR}/${node}/build.sh"
    ) ; prev_cmd_failed
done
