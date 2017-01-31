# -*- coding: utf-8 -*-

Fabricator(:datapath, class_name: Vnet::Models::Datapath) do
  display_name "test-datapath"

  dpid { "0x%x" % sequence(:dpid, 0xAAAAAAAA) }
end

Fabricator(:datapath_1, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test1'
  display_name "test-datapath1"
  dpid 0xaaaaaaaaaaaaaaaa
  node_id 'vna'
end

Fabricator(:datapath_2, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test2'
  display_name "test-datapath2"
  dpid 0xbbbbbbbbbbbbbbbb
  node_id 'vna2'
end

Fabricator(:datapath_3, class_name: Vnet::Models::Datapath) do
  uuid 'dp-test3'
  display_name "test-datapath3"
  dpid 0xcccccccccccccccc
  node_id 'vna3'
end
