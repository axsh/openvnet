#!/bin/bash  # -x

set -e

pname=`basename $0`
chefbento_url=opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox

function usage {
  echo
  echo "   ${pname} centos_version "
  echo "   centos_version=6.5, 6.8 or 7.2 "
  echo
}

########################  "main()"  ################################
if [ $# -ne 1 ]; then
  usage
  exit 1
fi

home=$PWD

case $1 in 
   6.5)  ## version assigned outside loop
       ;;
   6.8)  ## version assigned outside loop
      echo "Testing ... 6.8 is not available. Sorry!"
      exit 9
     ;;
   7.2)  ## version assigned outside loop
      echo "Testing ... 7.2 is not available. Sorry!"
      exit 9
     ;;
     *)
       usage
       exit 1
     ;;
esac
centos_ver=$1

dstring=`date "+%Y-%m-%d_%H%M%S"`

### 'curl' the required file from chef/bento
box_template=opscode_centos-OSVERSION_chef-provisionerless.box

#box=`echo ${box_template} | sed -e "s/OSVERSION/${centos_ver}/"`
box=${box_template/OSVERSION/${centos_ver}}
remote_box=${chefbento_url}/${box}

echo "Required box file is: ${remote_box}..."

temp_ovf_dir=${dstring}__${centos_ver}

mkdir ${temp_ovf_dir}
echo "curl -o ${temp_ovf_dir}/${box}  -R ${remote_box}  "
curl -o ${temp_ovf_dir}/${box}  -R ${remote_box} 

if [ $? -ne 0 ]; then
  echo "curl failed ..."
  exit 1
fi

### Untar!
cd ${temp_ovf_dir}
echo "tar xvf ${box} "
tar xvf ${box}

if [ $? -ne 0 ]; then
   echo "tar failed ..."
   exit 1
fi

cd $home


#
# automatic ssh setup: generate the tmp.ssh_setup.sh provisioning script
# BAD POINT:  This script name (tmp.ssh_setup.sh) will be hardwired
# into the vm_build.sh script. (In other words, that script expects
# this file.)  This is not very neat, and should be handled better...
#
ssh_provision_script=tmp.ssh_setup.sh

./ssh_setup.sh
if [ $? -ne 0 ]; then
   echo 
   echo "  FAILED to generate/find $HOME/.ssh/id_rsa.pub! "
   echo
   exit 2
fi

######## Now begin building the boxes
#
#     A note on vm output names. For now, the rule defining
# the name is: packer-${vm_name}-virtualbox/${vm_name}.ovf where
# ${vm_name} is the name of the boxes in the 'for vm in ...; do'
# block.
#  

base_provisioned_box_dir=packer-base_provisioned-virtualbox
base_provisioned_box=base_provisioned
rm -rf ${base_provisioned_box_dir}

time ./vm_build.sh $centos_ver ${base_provisioned_box} ${temp_ovf_dir}/box.ovf NONE  -provisioners base.sh

provisioned_ovf_base=${base_provisioned_box_dir}/${base_provisioned_box}.ovf


for vm in itest-edge itest1 itest2 itest3; do
#  time ./vm_build.sh $centos_ver centos-${centos_ver}-${vm} ${provisioned_ovf_base} ${vm}
   time ./vm_build.sh $centos_ver ${vm} ${provisioned_ovf_base} ${vm}
done

#/bin/rm -f ${ssh_provision_script}

exit $?
