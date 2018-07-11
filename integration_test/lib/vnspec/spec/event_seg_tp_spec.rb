# -*- coding: utf-8 -*-

require_relative 'spec_helper'
require_relative 'shared_examples/simple'

describe 'event_seg_tp', :vms_disable_dhcp => true do
  describe 'fail after deleting first tp_nw' do
    before(:all) {
      vm1.change_ipv4_address('10.101.0.10')
      vm2.change_ipv4_address('10.101.0.10')
      vm3.change_ipv4_address('10.101.0.11')
      vm4.change_ipv4_address('10.101.0.11')
      vm5.change_ipv4_address('10.101.0.12')
      vm6.change_ipv4_address('10.101.0.12')

      Vnspec::Models::Topology.add_segment('topo-vnet', 'seg-vseg1')
      Vnspec::Models::Topology.add_segment('topo-vnet', 'seg-vseg2')

      sleep 5

      Vnspec::Models::Topology.remove_segment('topo-vnet', 'seg-vseg1')
      sleep 5
    }

    include_examples 'simple examples fail first set'
  end

  describe 'success after re-adding' do
    before(:all) {
      Vnspec::Models::Topology.add_segment('topo-vnet', 'seg-vseg1')
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
      vms.parallel_each { |vm| vm.clear_arp_cache }

      Vnspec::Models::Topology.add('topo-vnet', 'simple_overlay')
      Vnspec::Models::Topology.add_underlay('topo-vnet', 'topo-physical')
      Vnspec::Models::Topology.add_segment('topo-vnet', 'seg-vseg1')
      Vnspec::Models::Topology.add_segment('topo-vnet', 'seg-vseg2')
      sleep 5
    }

    include_examples 'simple examples'
  end

end
