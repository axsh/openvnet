Fabricator(:datapath, class_name: Vnet::Models::Datapath) do
  display_name "test-datapath"
  dc_segment { Fabricate(:dc_segment) }
  ip_address { Fabricate(:ip_address) }
end

Fabricator(:datapath_1, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test1'
  display_name "test-datapath1"
  ip_address { Fabricate(:ip_address) }
  dpid "0x#{'a' * 16}"
  dc_segment_id 1
  node_id 'vna'
  is_connected true
end

Fabricator(:datapath_2, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test2'
  display_name "test-datapath2"
  ip_address { Fabricate(:ip_address) }
  dpid "0x#{'b' * 16}"
  dc_segment_id 1
  node_id 'vna2'
  is_connected true
end

Fabricator(:datapath_3, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test3'
  display_name "test-datapath3"
  ip_address { Fabricate(:ip_address) }
  dpid "0x#{'c' * 16}"
  dc_segment_id 2
  node_id 'vna3'
  is_connected true
end
