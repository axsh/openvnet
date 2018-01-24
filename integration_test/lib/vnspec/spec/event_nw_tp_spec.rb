# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/simple'

describe 'event_nw_tp' do
  before(:all) {
    API.request(:post, "topologies/topo-vnet/networks", network_uuid: 'nw-vnet1')
    API.request(:post, "topologies/topo-vnet/networks", network_uuid: 'nw-vnet2')

    sleep 5
  }

  include_examples 'simple examples'
end
