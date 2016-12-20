#!/bin/bash  # -x

function gen_key {
    key_file=$1    ## This should be $HOME/.ssh/id_rsa!

    ssh-keygen -t rsa -N "" -f ${key_file}
}

function exit_on_error {
   status=$1
   emess=$2

   if [ ${status} -ne 0 ]; then
       echo "${emess}"
       exit 2
   fi
}

############################################

if [ ! -e $HOME/.ssh/id_rsa ]; then

    if [ ! -e $HOME/.ssh ]; then
         mkdir -p $HOME/.ssh

         exit_on_error $? "Failed to mkdir '$HOME/.ssh' "
    fi

    gen_key $HOME/.ssh/id_rsa
    exit_on_error $?  "Failed to generate $HOME/.ssh/id_rsa keys"

fi


ssh_key=$(cat $HOME/.ssh/id_rsa.pub)

cat <<EOF > tmp.ssh_setup.sh

mkdir -p ~/.ssh 2>/dev/null
echo ${ssh_key} > ~/.ssh/authorized_keys
cat <<SSH > ~/.ssh/id_rsa
$(cat ${HOME}/.ssh/id_rsa)
SSH
chmod -R 700 ~/.ssh
chmod 600 ~/.ssh/*
EOF
