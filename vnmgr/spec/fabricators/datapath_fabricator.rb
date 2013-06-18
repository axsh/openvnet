require 'ipaddr'
Fabricator(:datapath, class_name: Vnmgr::Models::Datapath) do
  uuid 'dp-test'
  open_flow_controller_id 1 #TODO: create fabrication
  display_name "test-datapath"
  ipv4_address IPAddr.new("192.168.1.1").to_i
  datapath_id 'a' * 16
  node_id 'vna'
  is_connected true
end
