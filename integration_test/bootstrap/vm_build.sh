#!/bin/bash  # -x
#
#
#

if [ $# -lt 4 ]; then
  echo
  echo "  `basename $0` centos_version  vm_name base_ovf_file vm_metadata_dir [-provisioners file1 [file2] [file3] ...]"
  echo
  echo "  Where centos_version=6.8 or 7.2 "
  echo
  exit 1
fi

centos_version=$1 
vm_name=$2 
base_ovf_file=$3 
vm_metadata_dir=$4 

#####  Process any additional provisioner file names  #####

##+
# The join_args function is used to take a (space-delimited) list and 
# list and join the elements together using ',' as the separator.
#
# Ideally, this function should be moved to a 'generic.sh'
# file and 'imported'.
##-
function join_args {
    local IFS=","
    echo "$*"
}

###+
# Check to see if provisioners (provisionining file names) have been given.
# Note that if the user specifies the -provisioners option but does not give
# any filenames after the option ... no action is taken. 
###-
if [ $# -eq 4 ]; then
    provisioners=""
else
   remaining_args=(${@:5})    ## We only need arguments beyond $4
   if [ ! "${remaining_args[0]}" == "-provisioners" ]; then
       echo
       echo " ERROR: Unrecognized option: \"-${remaining_args[0]}\" "
       echo
       exit 2
   fi
   provisioners=`join_args "${remaining_args[@]:1}"`
   echo "Additional provisioners: ${provisioners}"
fi


### Packer templating
function base_packer_template {

    local base_ovf_file=$1            ## The base image/.ovf file to be used by packer
    local vm_name=$2
    local provision_scripts_list=$3

###+
#   This vulgarity is needed since packer requires each
# provisioning script file name to be specified on its
# own line. The list is input here as a comma-separated
# list. Change the commas to '\n', do `echo -e ${provision_scripts_list}`.
# Alas, scripting does often unleash such unpleasantness.
###-
    provision_scripts_list=${provision_scripts_list//,/\",'\n'\"}

template_var=$(cat << EOF
{
  "builders": [
    {
      "boot_wait": "10s",
      "guest_additions_path": "VBoxGuestAdditions_{{.Version}}.ovf",
      "headless": "",
      "http_directory": "http",
      "output_directory": "packer-${vm_name}-virtualbox",
      "shutdown_command": "echo 'vagrant' | sudo -S shutdown -P now",
      "ssh_password": "vagrant",
      "ssh_port": 22,
      "ssh_username": "vagrant",
      "ssh_wait_timeout": "10m",
      "type": "virtualbox-ovf",
      "source_path": "${base_ovf_file}",
      "virtualbox_version_file": ".vbox_version",
      "vm_name": "${vm_name}"VBOXMANAGE_STUB
    }
  ],
  "provisioners": [
    {
      "execute_command": "echo 'vagrant' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'",
      "scripts": [
        "packer_scripts/networking.sh",
        "packer_scripts/vagrant.sh",
        "`echo -e ${provision_scripts_list}`"
      ],
      "type": "shell"
    }
  ],
  "variables": {
    "build_timestamp": "{{isotime \"20060102150405\"}}",
    "headless": "",
    "version": "2.1.TIMESTAMP"
  }
}

EOF
)


echo "${template_var}"

}  ### End, function base_packer_template

####################################################################

###+
# Generate the provisioning scripts that will place network config.
# files onto the machine being built. These scripts look into the
# directory given by ${vm_metadata_dir} to find the information
# needed. The script will output the list of .sh files it generated.
# This list is later written into the packer template file that will
# be used.
#
# Tack this list onto the end of the list of any provisioner files
# given by the user on the command line (via -provisioners).
###-
#script_file_list=`./make_network_template_files.sh ${vm_metadata_dir}`

###+
# This hack is required due to a change in the program logic -- I'd not
# considered an important problem/point: The initially provisioned box
# must not re-write network scripts! In future, the vm_metadata_dir
# directory must be made to be optional!
###-
ssh_setup_script=tmp.ssh_setup.sh
if [ "${vm_metadata_dir}" == "NONE" ]; then
    script_file_list=${provisioners}
    nic_cmd_list=""
else
#   script_file_list="${provisioners},`./make_network_template_files.sh ${vm_metadata_dir}`"
    script_file_list="${provisioners},"${ssh_setup_script}",`./make_network_template_files.sh ${vm_metadata_dir}`"
    
    ## Now add for lxc containers, as needed
    if [ -e ${vm_metadata_dir}/metadata/lxc ]; then
        script_file_list="${script_file_list},`./lxc_network_setup.sh ${vm_name}`"
    fi
    script_file_list=${script_file_list#,}

#   nic_cmd_list=$( ./generate_niclist.sh ${vm_metadata_dir} )
    nic_cmd_list=$( ./nic_info.sh ${vm_metadata_dir} )
    nic_cmd_list=${nic_cmd_list#,}
fi

echo "Provisioning script files: ${script_file_list}..."

###+
#   Here we build the packer template file in two passes:
# The first pass fills in the mandatory parameters -- vm_name,
# etc. In the second pass, optional parameters are subsituted
# into the variable created during the first pass. Most likely,
# the only optional parameters are "vboxmanage" commands to 
# add NIC's to the virtual machine.
###-

# Pass 1: mandatory information
base_template=$(base_packer_template  ${base_ovf_file} ${vm_name}  ${script_file_list} )

# Pass 2: optional information
vbox_cmd_temp=$(cat <<VBOX
      "vboxmanage_post": [
              ${nic_cmd_list//,[/,\n              [}
          ]
VBOX
)

if [ ! "${nic_cmd_list}" == "" ]; then
#   nic_cmd_list="      \"vboxmanage\": [\n           ${nic_cmd_list//,[/,\n           [} \n         ]"
    full_packer_template=${base_template/VBOXMANAGE_STUB/,'\n'${vbox_cmd_temp}}
else
    full_packer_template=${base_template/VBOXMANAGE_STUB/}
fi


template_file=centos-${centos_version}-${vm_name}.json
echo -e "${full_packer_template}" > ${template_file}

## Do a quick check on the packer template file
echo "packer validate ${template_file}"
packer validate ${template_file}


if [ $? -ne 0 ]; then
  echo
  echo "Bad template file: \"${template_file}\". "
  echo
  exit 2
fi

echo "packer build  ${template_file} ..."

      exit 22   ### HERE here

packer build  ${template_file}

if [ $? -ne 0 ]; then
  exit 1
fi

#rm ${template_file}
exit 0
