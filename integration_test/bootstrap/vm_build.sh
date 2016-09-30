#!/bin/bash   # -x
#
#
#

if [ $# -lt 4 ]; then
  echo
  echo "  `basename $0` centos_version  vm_name base_ovf_file vm_metadata_dir [-provisioners file1 [file2] [file3] ...]"
  echo "   centos_version=6.8 or 7.2 "
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
   remaining_args=(${@:5:$#})    ## We only need arguments beyond $4
   if [ ! "${remaining_args[0]}" == "-provisioners" ]; then
       echo
       echo " ERROR: Unrecognized option: \"-${remaining_args[0]}\" "
       echo
       exit 2
   fi
   provisioners=`join_args "${remaining_args[@]:1}"`
   echo "Additional provisioners: ${provisioners}"
fi

#box_base=centos-${centos_version}
##############################################################

### Packer templating
function build_packer_template {

    local base_ovf_file=$1            ## The base image/.ovf file to be used by packer
    local vm_name=$2
    local provision_scripts_list=$3
    local template_file=$4 

###+
#   This vulgarity is needed since packer requires each
# provisioning script file name to be specified on its
# own line. The list is input here as a comma-separated
# list. Change the commas to '\n', do `echo -e ${provision_scripts_list}`.
# Alas, scripting does often unleash such unpleasantness.
###-
    provision_scripts_list=${provision_scripts_list//,/\",'\n'\"}

    cat > ${template_file} << EOF
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
      "vm_name": "${vm_name}"
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

echo "Created ${template_file}..."

}  ### End, function build_packer_template

####################################################################

###+
# Generate the provisioning scripts that will place network config.
# files onto the machine being built. These scripts look into the
# directory given by ${vm_metadata_dir} to find the information
# needed. The script will output the list of .sh files it generated.
# This list is later written into the packer template file that will
# be used.
###-
#script_file_list=`./make_network_template_files.sh ${vm_metadata_dir}`
script_file_list="${provisioners},`./make_network_template_files.sh ${vm_metadata_dir}`"
script_file_list=${script_file_list#,}

echo "provisioning script files: ${script_file_list}..."

template_file="centos-"${centos_version}.json
build_packer_template  ${base_ovf_file} ${vm_name}  ${script_file_list} ${template_file}

if [ ! -e ${template_file} ]; then
    echo "Template file ${template_file} not found!"
    exit 1
fi

## Do a quick check on the packer template file
echo "packer validate ${template_file}"
packer validate ${template_file}

if [ $? -ne 0 ]; then
  echo
  echo "Bad template file: \"${template_file}\". "
  echo
  exit 2
fi

      exit 2

echo "packer build  ${template_file} ..."
packer build  ${template_file}

if [ $? -ne 0 ]; then
  exit 1
fi

#rm ${template_file}
exit 0

