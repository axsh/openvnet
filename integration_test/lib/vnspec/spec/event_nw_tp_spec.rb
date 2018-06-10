# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/simple'

describe 'event_nw_tp' do
  describe 'fail after deleting first tp_nw' do
    before(:all) {
      Vnspec::Models::Topology.add_network('topo-vnet', 'nw-vnet1')
      Vnspec::Models::Topology.add_network('topo-vnet', 'nw-vnet2')
      sleep 5

      Vnspec::Models::Topology.remove_network('topo-vnet', 'nw-vnet1')
      sleep 5
    }

    include_examples 'simple examples fail first set'
  end

  describe 'success after re-adding topology network' do
    before(:all) {
      Vnspec::Models::Topology.add_network('topo-vnet', 'nw-vnet1')
      sleep 5
    }

    include_examples 'simple examples'
  end

  describe 'fail after deleting topology' do
    before(:all) {
      Vnspec::Models::Topology.delete('topo-vnet')
      sleep 5
    }

    include_examples 'simple examples fail'
  end

  describe 'success after recreating topology' do
    before(:all) {
      Vnspec::Models::Topology.add('topo-vnet', 'simple_overlay')
      Vnspec::Models::Topology.add_underlay('topo-vnet', 'topo-physical')
      Vnspec::Models::Topology.add_network('topo-vnet', 'nw-vnet1')
      Vnspec::Models::Topology.add_network('topo-vnet', 'nw-vnet2')
      sleep 5
    }

    include_examples 'simple examples'
  end

end
