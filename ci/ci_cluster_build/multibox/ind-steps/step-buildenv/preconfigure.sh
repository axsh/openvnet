
$REBUILD && {
    cleanup_environment
} || {
    (
        $starting_step "Clone base images from ${BASE_BRANCH}"
        [ -d "${CACHE_DIR}/${BRANCH}" -o ! -d "${CACHE_DIR}/${BASE_BRANCH}" ]
        $skip_step_if_already_done ; set -ex
        cp -r "${CACHE_DIR}/${BASE_BRANCH}" "${CACHE_DIR}/${BRANCH}"
    ) ; prev_cmd_failed
}

(
    $starting_step "Create cache folder"
    [ -d "${CACHE_DIR}/${BRANCH}" ]
    $skip_step_if_already_done ; set -ex
    mkdir -p "${CACHE_DIR}/${BRANCH}"
) ; prev_cmd_failed

masquerade "${NETWORK}/${PREFIX}"
