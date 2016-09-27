#!/bin/bash

##+
#
#     packer will be used to provision vm's. This particular script
# generates the shell scripts for setting up the network interfaces
# (eg. ifcfg-eth0). These shell scripts will be run on the virtual
# machine during the provisioning process.
#
##-

if [ $# -ne 1 ]; then
   echo
   echo "  $0  metadata_dirname "
   echo
   exit 1
fi

base_dir=$1

##+
#    Generate a shell script that will concatenate the contents of
# a (local) network config. file into the appropriate location on
# the given vm.
##-
function gen_ifcfg_script {
    local out_file=$1
    local device_file=$2           ## eg, ifcfg-eth0
    local device_file_path=$3


    echo '#!/bin/bash' > ${out_file}
    echo "cat > /etc/sysconfig/network-scripts/${device_file} << 'EOF'" >> ${out_file}
    cat ${device_file_path}/${device_file} >> ${out_file} 
    echo "EOF" >> ${out_file}
}

################################################

script_file_list_str=""
for ifcfg_dev in ` ls ${base_dir}/metadata/ifcfg-*`; do
   dev=`basename ${ifcfg_dev}`

#   echo ${dev}
   out=${base_dir}/tmp.${dev}

#  echo " gen_ifcfg_script ${out} ${dev} ${base_dir}/metadata "
   gen_ifcfg_script ${out} ${dev} ${base_dir}/metadata

   script_file_list_str="${script_file_list_str},`basename ${base_dir}`/tmp.${dev}"

done

echo ${script_file_list_str#,}
