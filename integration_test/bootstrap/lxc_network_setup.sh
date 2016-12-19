#!/bin/bash 

function net_setup {
    out=$1
    lxc_name=$2
    tp=$3
    hw=$4
    ip=$5

    if [ "${ip}" == "" ]; then
        ip_line="#lxc.network.ipv4 = "
    else
        ip_line="lxc.network.ipv4 = ${ip}"
    fi

    cat <<EOF >> ${out}
lxc.network.type = veth
lxc.network.flags = up
lxc.network.veth.pair = ${tp}
lxc.network.hwaddr = ${hw}
${ip_line}

EOF

}

function net_info {
    local file=$1
    local ofile=$2
    local lxc_name=$3

    while read -r tp hw ip; do
        net_setup ${ofile} ${lxc_name} $tp $hw $ip 
    done < ${file}
}

function finish_config_file {
    file=$1
    lxc_name=$2

    cat << EOF >> ${file}
lxc.rootfs = /var/lib/lxc/${lxc_name}/rootfs
lxc.include = /usr/share/lxc/config/centos.common.conf
lxc.arch = x86_64
lxc.utsname = ${lxc_name}
lxc.autodev = 0
EOF

}

function lxc_setup {
    prov_script_file=$1
    lxc1=$2
    lxc2=$3

    /bin/rm -f ${prov_script_file}

    script_file_on_vm=/root/lxc_setup.sh

cat > ${prov_script_file} << EOF
    echo '#!/bin/bash' > ${script_file_on_vm}

    echo "lxc-start -n ${lxc1} -d  2>/dev/null" >> ${script_file_on_vm}
    echo "lxc-start -n ${lxc2} -d  2>/dev/null" >> ${script_file_on_vm}
    echo "sleep 10" >> ${script_file_on_vm}                  # Give the container time to start up

    echo "ovs-vsctl del-port br0 ${lxc1}_tap0 2>/dev/null " >> ${script_file_on_vm} 
    echo "ovs-vsctl del-port br1 ${lxc1}_tap1 2>/dev/null"  >> ${script_file_on_vm} 
    echo "ovs-vsctl del-port br0 ${lxc2}_tap0 2>/dev/null " >> ${script_file_on_vm} 
    echo "ovs-vsctl del-port br1 ${lxc2}_tap1 2>/dev/null " >> ${script_file_on_vm} 

    echo "ovs-vsctl add-port br0 ${lxc1}_tap0" >> ${script_file_on_vm} 
    echo "ovs-vsctl add-port br1 ${lxc1}_tap1" >> ${script_file_on_vm} 
    echo "ovs-vsctl add-port br0 ${lxc2}_tap0" >> ${script_file_on_vm} 
    echo "ovs-vsctl add-port br1 ${lxc2}_tap1" >> ${script_file_on_vm} 
EOF

#   echo ${prov_script_file}

}

function lxc_bridge_connect {

    outfile=$1
    lxc1=$2
    lxc2=$3

    /bin/rm -f ${outfile}

    script_file_on_vm=lxc_setup.sh

    echo '#!/bin/bash' >> ${outfile}
    echo "ovs-vsctl add-port br0 ${lxc1}_tap0" >> ${outfile} 
    echo "ovs-vsctl add-port br1 ${lxc1}_tap1" >> ${outfile} 

    echo "ovs-vsctl add-port br0 ${lxc2}_tap0" >> ${outfile} 
    echo "ovs-vsctl add-port br1 ${lxc2}_tap1" >> ${outfile} 

}

function setup_root_bashinit {

    prov_script_name=$1
    bash_file=/root/.bash_profile

cat << EOF > ${prov_script_name} 
#!/bin/bash
sudo echo 'chmod +x  /root/lxc_setup.sh' >> ${bash_file}
sudo echo /root/lxc_setup.sh >> ${bash_file}
EOF

}

##################################################################

if [ $# -ne 1 ]; then
   echo "$0  vm_name"
   exit 2
fi
vmdir=$1


if [ ! -e ${vmdir}/metadata/lxc ]; then
    echo "No lxc dir..."
    exit 1
fi

script_file_list_str=""
## Assumption here: Only files giving lxc container info. are in this dir!
for container in `ls ${vmdir}/metadata/lxc`; do

   outfile=${vmdir}/tmp.${container}.config.sh
   /bin/rm -f ${outfile}
   touch ${outfile}

   echo '#!/bin/bash' > ${outfile}
   echo "cat > /var/lib/lxc/${lxc}/config << 'EOF'" >> ${outfile}

   net_info ${vmdir}/metadata/lxc/${container}/network.info ${outfile} ${container}
   finish_config_file ${outfile} ${container}

   echo "EOF" >> ${outfile}

   script_file_list_str="${script_file_list_str},${outfile}"
done

##
#lxc_start_script=${vmdir}/tmp.lxc_start.sh
#lxc_start ${lxc_start_script} inst1 inst2

#script_file_list_str="${script_file_list_str}",${lxc_start_script}

#lxc_bconnect_script=${vmdir}/tmp.lxc_bridge.sh
#lxc_bridge_connect ${lxc_bconnect_script} inst1 inst2

lxc_setup_provisioner=${vmdir}/tmp.lxc_setup.sh
lxc_setup ${lxc_setup_provisioner} inst1 inst2

vm_bash_init=${vmdir}/tmp.bash_init.sh         # File to modify the .bash_profile file on the vm.
                                               # This is needed to run lxc startup scripts & bridge-connecting
setup_root_bashinit ${vm_bash_init}
script_file_list_str="${script_file_list_str}",${lxc_setup_provisioner},${vm_bash_init}

echo ${script_file_list_str#,}
