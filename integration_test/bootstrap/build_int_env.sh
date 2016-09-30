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
# echo "  `basename $0` centos_version "
# echo
# echo "   centos_version=6.5, 6.8 or 7.2 "
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
#url=opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/
#prefix=opscode_centos-
#suffix=_chef-provisionerless.box

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

######## Now begin building the boxes
#
#     A note on vm output names. For now, the rule defining
# the name is: packer-${vm_name}-virtualbox/${vm_name}.ovf where
# ${vm_name} is the name of the boxes in the 'for vm in ...; do'
# block.
#  

  first_build_vm= <the first vm to be built>
  provisioned_ovf_base=packer-${first_build_vm}-virtualbox/${first_build_vm}.ovf


for vm in itest-edge itest1 itest2 itest3; do
   time ./vm_build.sh $centos_ver centos-${centos_ver}-${vm} ${temp_ovf_dir} ${vm}
done

exit $?
