#!/bin/bash

for node in ${scheduled_nodes[@]} ; do
    (
        $starting_group "Building ${node%,*}"
        [[ "${node}" == "base" && -f "${CACHE_DIR}/${BRANCH}/box-disk1.raw" ]]
        $skip_group_if_unnecessary
        "${ENV_ROOTDIR}/${node}/build.sh"
    ) ; prev_cmd_failed
done
