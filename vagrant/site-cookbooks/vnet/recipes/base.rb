node[:vnet][:interfaces].each do |interface|
  template "/etc/sysconfig/network-scripts/ifcfg-#{interface[:device]}" do
    source "ifcfg.erb"
    owner "root"
    group "root"
    variables interface
  end

  execute "ifdown #{interface[:device]}"
  execute "ifup #{interface[:device]}"
end
