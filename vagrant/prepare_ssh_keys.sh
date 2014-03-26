#!/bin/bash
#
# execute after vagrant up
#

private_key=${1-~/.vagrant.d/insecure_private_key}

ssh_dir=$(dirname $0)/vm/ssh

mkdir -p ${ssh_dir}
cp ${private_key} ${ssh_dir}/id_rsa
ssh-keygen -y -f ${ssh_dir}/id_rsa > ${ssh_dir}/authorized_keys
