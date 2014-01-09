Fabricator(:datapath, class_name: Vnet::Models::Datapath) do
  display_name "test-datapath"
  dc_segment { Fabricate(:dc_segment) }
  ipv4_address { sequence(:ipv4_address, IPAddr.new("192.168.1.1").to_i) }
end

Fabricator(:datapath_1, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test1'
  display_name "test-datapath1"
  ipv4_address IPAddr.new("192.168.1.1").to_i
  dpid 0xaaaaaaaaaaaaaaaa
  dc_segment_id 1
  node_id 'vna'
  is_connected true
end

Fabricator(:datapath_2, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test2'
  display_name "test-datapath2"
  ipv4_address IPAddr.new("192.168.1.2").to_i
  dpid 0xbbbbbbbbbbbbbbbb
  dc_segment_id 1
  node_id 'vna2'
  is_connected true
end

Fabricator(:datapath_3, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test3'
  display_name "test-datapath3"
  ipv4_address IPAddr.new("192.168.2.2").to_i
  dpid 0xcccccccccccccccc
  dc_segment_id 2
  node_id 'vna3'
  is_connected true
end
