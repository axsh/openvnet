# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/simple'

describe 'event_nw_tp' do
  before(:all) {
    Vnspec::Models::TopologyNetwork.create(
      topology_uuid: 'topo-vnet',
      network_uuid: 'nw-vnet1'
    )
    Vnspec::Models::TopologyNetwork.create(
      topology_uuid: 'topo-vnet',
      network_uuid: 'nw-vnet2'
    )

    sleep 5
  }

  include_examples 'simple examples'
end
