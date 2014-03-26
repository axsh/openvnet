#
# Cookbook Name:: docker_registry
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

node["docker_registry"]["packages"].each do |pkg|
  package pkg
end

include_recipe "ntp"
include_recipe "docker"

# https://github.com/dotcloud/docker/issues/2683
package "cgroup-lite"

bash "run_registry" do
  code <<-eos
    docker stop registry > /dev/null 2>&1 || :
    docker rm registry > /dev/null 2>&1 || :
    docker run -d -p 5000:5000 -v /srv/registry:/srv/registry --name registry registry
  eos
end

bash "create_vm_image" do
  code <<-EOS
    docker build -t localhost:5000/vmbase --rm /vagrant/vm
  EOS
end

bash "push_vm_image" do
  retries 3
  code <<-EOS
    docker push localhost:5000/vmbase
  EOS
end
