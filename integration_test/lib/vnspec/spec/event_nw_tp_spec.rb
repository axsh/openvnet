# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/simple'

describe 'event_nw_tp' do
  before(:all) {
    Vnspec::Models::Topology.add_network('topo-vnet', 'nw-vnet1')
    Vnspec::Models::Topology.add_network('topo-vnet', 'nw-vnet2')
    sleep 5
  }

  describe 'success on initial setup' do
    include_examples 'simple examples'
  end

  describe 'fail after deleting topology' do
    before(:all) {
      Vnspec::Models::Topology.delete('topo-vnet')
      sleep 5
    }

    include_examples 'simple examples fail'
  end

end
