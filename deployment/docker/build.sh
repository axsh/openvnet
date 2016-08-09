#!/bin/bash
# Run build process in docker container.

set -ex -o pipefail

CID=
function docker_rm() {
    if [[ -z "$CID" ]]; then
        return 0
    fi
    docker rm -f "$CID" 
}

trap "docker_rm" EXIT

img_tag="openvnet/${BRANCH_NAME}"
docker build -t "${img_tag}" - < "./deployment/docker/el7.Dockerfile"
CID=$(docker run -d "${img_tag}")
docker exec -t "${CID}" mkdir "/var/tmp/openvnet"
docker cp . "${CID}:/var/tmp/openvnet"
docker exec -t "${CID}" /bin/bash -c "cd openvnet; ./deployment/packagebuild/build_packages_vnet.sh"
