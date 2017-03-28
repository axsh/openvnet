#!/bin/bash  # -x

set -e

###+
#
#    Script to build the openvnet integration test environment.
# All vm's created are written to directories located in the
# current directory. The directories have names defined by the
# following structure:
#
# packer-<vm_name>-virtualbox
#
# So, for example:  packer-itest3-virtualbox.
#
# NOTES:
#
#    (1)  The script will FAIL if virtualbox is run in gui mode.
#         The script that builds individual machines (vm_build.sh)
#         has "headless" : "true"  set in the packer template files,
#         so this shouldn't be a problem. However, if the script
#         is run with virtualbox already running in gui mode, it is
#         possible that the script could fail. (You will see an error
#         reading something like "..could not realese lock on virutal
#         machine ...")
#
#    (2)  Before running this script, the init_host_bridges.sh script
#         ought to be run. This script sets up the 'hostonly' network
#         on the host machine.
#
#    (3)  The script makes use of packer: The user must have this
#         software/executable somewhere in the execution path.
#
#    (4)  Once the vm's have been built, the system_startup.sh script
#         can be run to import the vm's into Virtual Box and to then
#         start them up. The vm's are started in _headless_ mode.
# 
#    (5)  packer will fail if the machine being built already exists in
#         Virtual Box. The user will need to delete any such instances
#         by hand.
#
# USAGE:
#         build_int_env.sh  6.5  [-basebox ovf_boxname ]
#
#         Currently, openvnet only builds on centos6.5! In future,
#         6.8 and 7.2 will be supported. For now, the first (required)
#         value to pass to the script is 6.5.
#
#         To avoid downloading a basebox from the chef/bento git
#         repository and use a previously downloaded & unpacked box,
#         use the "-basename ovf_boxname" option. Here, "boxname"
#         must be the full path the image, which must be an .ovf file.
###-

pname=`basename $0`
chefbento_url=opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox

function usage {
   echo
   echo "   ${pname} centos_version [-basebox ovf_boxname]"
   echo
   echo "   centos_version=6.5, 6.8 or 7.2 "
   echo "   ovf_boxname is the full path to the .ovf file"
   echo
}

function user_centosver {
   arg=$1

   case ${arg} in 
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

   echo ${arg}

}

function download_box {

   centos_ver=$1

   home=$PWD
   dstring=`date "+%Y-%m-%d_%H%M%S"`

   ### 'curl' the required file from chef/bento
   box_template=opscode_centos-OSVERSION_chef-provisionerless.box

   box=${box_template/OSVERSION/${centos_ver}}
   remote_box=${chefbento_url}/${box}

#  echo "Required box file is: ${remote_box}..."
   
   temp_ovf_dir=${dstring}__${centos_ver}
 
   mkdir ${temp_ovf_dir}
#  echo "curl -o ${temp_ovf_dir}/${box}  -R ${remote_box}  "
   curl -o ${temp_ovf_dir}/${box}  -R ${remote_box} 
   
   if [ $? -ne 0 ]; then
     echo "curl -o ${temp_ovf_dir}/${box}  -R ${remote_box}  "
     echo "curl failed ..."
     exit 1
   fi
   
   ### Untar!
   cd ${temp_ovf_dir}
#  echo "tar xvf ${box} "
   tar xvf ${box}
   
   if [ $? -ne 0 ]; then
      echo "tar xvf ${box} "
      echo "tar failed ..."
      exit 1
   fi
   
   cd $home

   echo ${temp_ovf_dir}/box.ovf

}

########################  "main()"  ################################
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

#home=$PWD

case $# in
     1) ## centos version assigned outside loop
        ver=$1
        user_box=""
        ;;
     3)
        ver=$1
        user_box=$3 
        ;;
     *)
        usage
        exit 1
esac

#centos_ver=$1
centos_ver=$(user_centosver ${ver})

if [ "${user_box}" == "" ]; then
    basebox=$(download_box ${centos_ver})
else
    if [ ! -e ${user_box} ]; then
       echo "  \"${user_box}\" not found! "
       exit 2
    fi
    basebox=${user_box}
fi

#dstring=`date "+%Y-%m-%d_%H%M%S"`

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
/bin/rm -rf ${base_provisioned_box_dir}

time ./vm_build.sh $centos_ver ${base_provisioned_box} ${basebox} NONE  -provisioners base.sh

provisioned_ovf_base=${base_provisioned_box_dir}/${base_provisioned_box}.ovf

for vm in itest1 itest2 itest3 router; do
   time ./vm_build.sh $centos_ver ${vm} ${provisioned_ovf_base} ${vm}
done

/bin/rm -f ${ssh_provision_script}

exit $?
