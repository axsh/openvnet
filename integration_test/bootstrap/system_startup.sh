#!/bin/bash  # -x

vboxmanage=VBoxManage

function startvm_headless {
   local vm=$1

   ${vboxmanage} startvm ${vm} --type headless
}

function shutdownvm {
   local vm=$1

   ${vboxmanage} controlvm ${vm} acpipowerbutton
}

function removevm {
   local vm=$1

   # We're killing this machine, so just pull the plug!
   ${vboxmanage} controlvm ${vm} poweroff 2>/dev/null

   ${vboxmanage} unregistervm ${vm} --delete 2> /dev/null
}

function importvm {
   local ovf=$1

   if [ ! -e ${ovf} ]; then
        echo "Full name of ovf -- including path! -- required."
   else
        echo " ${vboxmanage} import ${ovf} ... "
#       ${vboxmanage} import ${ovf}  > ${log}
        ${vboxmanage} import ${ovf} &>/dev/null
   fi
}

###############################################################


for vm in itest-edge itest1 itest2 itest3; do
    vmbox=packer-${vm}-virtualbox/${vm}.ovf

    echo "Will remove ${vm}..."
    removevm ${vm}

    echo "Importing ${vmbox} into virtual box... "
    importvm ${vmbox}

    if [ $? -ne 0 ]; then
       echo "** Import failed for \"${vmbox}\".  {$vm} failed..."
       exit 2
    fi

    # Now start up
    startvm_headless ${vm}
    if [ $? -ne 0 ]; then
        echo "** Startup failed for ${vm}..."
        exit 1
    fi
    echo
done

