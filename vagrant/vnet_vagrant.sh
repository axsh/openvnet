#!/bin/bash

set -x

command=$1

#docker_registry="registry"
vnet_vms="
vnmgr
vna1
vna2
vna3
edge
legacy
router
"
case $command in

install)

  #vagrant plugin install vagrant-berkshelf
  #vagrant plugin install vagrant-vbox-snapshot
  
  vagrant up
  
  bundle exec berks install --path cookbooks
  
  ./ssh_config.rb -y

  #bundle exec knife solo prepare ${docker_registry} 
  #bundle exec knife solo cook ${docker_registry} 

  for node in $vnet_vms ; do
    bundle exec knife solo prepare ${node}
  done

  for node in $vnet_vms ; do
    bundle exec knife solo cook ${node}
  done

  ;;

*|update)

  for node in $vnet_vms ; do
    bundle exec knife solo cook ${node} 
  done

  ;;

esac
