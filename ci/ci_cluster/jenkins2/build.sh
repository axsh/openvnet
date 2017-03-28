#!/bin/bash
# Build OpenVNet CI Cluster machine images based on Chef's bento box images.
# Virtualbox is required.
set -e -o pipefail

# Confirm packer is available. Download if not.
if ! type packer &> /dev/null; then
  export PATH=".:$PATH"
  if ! type packer &> /dev/null; then
    # zcat seems to support .zip.
    curl -L "https://releases.hashicorp.com/packer/0.10.2/packer_0.10.2_$(uname -s | tr '[:upper:]' '[:lower:]')_amd64.zip" | zcat > packer
  fi
fi

function fetch_box() {
  local dist=$1
  box_url="http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_${dist}_chef-provisionerless.box"
  box_tmp="boxtemp/${dist}"

  # ignore duplicating dir
  mkdir -p $box_tmp  || :

  (
    cd $box_tmp
    if [ -f './etag' ]; then
        etag=$(cat ./etag)
    fi
    curl --dump-header box.header ${etag:+-H "If-None-Match: ${etag}"} -o "t.box" "${box_url}"
    cat box.header | awk 'BEGIN {FS=": "}/^ETag/{print $2}' > ./etag
    rm -f box.header
    tar -xzf t.box
    # Will see box.ovf and disk image files.
  )
}

mkdir ./boxtemp || :

export JENKINS_RPM=jenkins-2.19.1-1.1.noarch.rpm
# Create local copy of jenkins package. Helps to rebuild speed.
if [ ! -f "boxtemp/${JENKINS_RPM}" ]; then
  curl -L -o "boxtemp/${JENKINS_RPM}" "http://pkg.jenkins-ci.org/redhat-stable/${JENKINS_RPM}"
fi

for dist in "centos-7.2" "centos-6.8"
do
  fetch_box $dist
done
HOST_SWITCH=vboxnet0 packer build centos7-master.json
HOST_SWITCH=vboxnet0 packer build centos6-slave.json

