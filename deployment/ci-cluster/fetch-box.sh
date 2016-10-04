#!/bin/bash

set -ex

#box_url="${1:?ERROR: Require to set download .box URL}"
box_url="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-7.2_chef-provisionerless.box"
box_tmp="${2:-boxtemp/7.2}"

# ignore duplicating dir
mkdir -p $box_tmp  || :

(
    cd $box_tmp
    if [ -f './.etag' ]; then
        etag=$(cat ./.etag)
    fi
    curl --dump-header box.header ${etag:+-H "If-None-Match: ${etag}"} -o "t.box" "${box_url}"
    cat box.header | awk 'BEGIN {FS=": "}/^ETag/{print $2}' > .etag
    rm -f box.header
    tar -xzf t.box
)
