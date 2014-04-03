Fabricator(:datapath, class_name: Vnet::Models::Datapath) do
  display_name "test-datapath"
end

Fabricator(:datapath_1, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test1'
  display_name "test-datapath1"
  dpid 0xaaaaaaaaaaaaaaaa
  node_id 'vna'
  is_connected true
end

Fabricator(:datapath_2, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test2'
  display_name "test-datapath2"
  dpid 0xbbbbbbbbbbbbbbbb
  node_id 'vna2'
  is_connected true
end

Fabricator(:datapath_3, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test3'
  display_name "test-datapath3"
  dpid 0xcccccccccccccccc
  node_id 'vna3'
  is_connected true
end
