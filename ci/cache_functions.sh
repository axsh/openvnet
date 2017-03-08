#!/bin/bash

if [[ -n "${1}" ]]; then
    build_cache_base="${1}"
fi

set_cache_vol () {
    local cache_vol_path="${1}"

    if [[ -n "${build_cache_base}" ]]; then
        cache_vol_path="${cache_vol_path}/${build_cache_base}"
    fi
    echo "${cache_vol_path}"
}

create_cache () {
    local cache_dir="${1}"
    local cache_vol=$(set_cache_vol "${2}")
    local commit_id="${3}"
    local cache_list="${4}"

    TMPDIR=$(mktemp -d)
    if [[ -n "${cache_dir}" ]]; then
        if [[ ! -w "${cache_vol}" ]]; then
            echo "ERROR: CACHE_VOLUME '${cache_dir}' is not writable." >&2
            exit 1
        fi

        if [[ ! -d "${cache_vol}" ]]; then
            mkdir -p "${cache_vol}"
        fi

        tar cO --directory=/ --files-from="${cache_list}" > "${cache_vol}/${commit_id}.tar"

        # Clear build cache files which no longer referenced from Git ref names (branch, tags)
        git show-ref --head --dereference | awk '{print $1}' > "${TMPDIR}/sha.a"
        for i in $(git reflog show | head -10 | awk '{print $2}'); do
            git rev-parse "$i"
        done >> "${TMPDIR}/sha.a"
        (cd "${cache_vol}"; ls *.tar) | cut -d '.' -f1 > "${TMPDIR}/sha.b"
        # Set operation: B - A
        join -v 2 <(sort -u ${TMPDIR}/sha.a) <(sort -u ${TMPDIR}/sha.b) | while read i; do
            echo "Removing build cache: ${CACHE_VOLUME}/${i}.tar"
            rm -f "${cache_vol}/${i}.tar" || :
        done
    fi


}

try_load_cache () {
    local cache_dir="${1}"
    local cache_vol=$(set_cache_vol "${2}")
    local commit_id="${3}"

    if [[ -n "${cache_dir}" ]]; then
        for f in $(ls "${cache_vol}"); do
            cached_commit=$(basename $f)
            cached_commit="${cached_commit%.*}"

            if git rev-list "${commit_id}" | grep "${cached_commit}" > /dev/null; then
                echo "FOUND build cache ref ID: ${cached_commit}"
                tar -xf "${cache_vol}/$f" -C "/"
                break
            fi
        done
    fi
}
