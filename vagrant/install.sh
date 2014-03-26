#!/bin/bash

#vagrant plugin install vagrant-berkshelf
vagrant plugin install vagrant-vbox-snapshot

vagrant up

bundle exec berks install --path cookbooks

./ssh_config.rb -y

for node in vnmgr vna1 vna2 vna3 edge registry; do
  bundle exec knife solo prepare ${node} 
  bundle exec knife solo cook ${node} 
done
