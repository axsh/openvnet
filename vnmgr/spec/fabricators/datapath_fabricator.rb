require 'ipaddr'
Fabricator(:datapath_1, class_name: Vnmgr::Models::Datapath) do
  uuid 'dp-test1'
  open_flow_controller_id 1 #TODO: create fabrication
  display_name "test-datapath1"
  ipv4_address IPAddr.new("192.168.1.1").to_i
  datapath_id 'a' * 16
  dc_segment_id 1
  node_id 'vna'
  is_connected true
end

Fabricator(:datapath_2, class_name: Vnmgr::Models::Datapath) do
  uuid 'dp-test2'
  open_flow_controller_id 2 #TODO: create fabrication
  display_name "test-datapath2"
  ipv4_address IPAddr.new("192.168.1.2").to_i
  datapath_id 'b' * 16
  dc_segment_id 1
  node_id 'vna2'
  is_connected true
end

Fabricator(:datapath_3, class_name: Vnmgr::Models::Datapath) do
  uuid 'dp-test3'
  open_flow_controller_id 3 #TODO: create fabrication
  display_name "test-datapath3"
  ipv4_address IPAddr.new("192.168.2.2").to_i
  datapath_id 'c' * 16
  dc_segment_id 2
  node_id 'vna3'
  is_connected true
end
