#!/bin/bash

stop_nfs () {
    service rpcbind stop
    service nfs stop
}

trap 'stop_nfs' ERR

cat <<EOF > /etc/exports
/repos               *(rw,sync,no_root_squash)
/cache               *(rw,sync,no_root_squash)
/opt/axsh/openvnet   *(rw,sync,no_root_squash)
EOF

service rpcbind start
service nfs start

current_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
${current_dir}/buildbox/build.sh
