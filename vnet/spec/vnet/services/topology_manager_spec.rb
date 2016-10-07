# -*- coding: utf-8 -*-

describe Vnet::Services::TopologyManager do

  let(:manager) { described_class.new(Vnet::Services::VnetInfo.new) }

  let(:pnet_1) { Fabricate(:pnet_public1) }
  let(:pnet_2) { Fabricate(:pnet_public2) }
  let(:vnet_1) { Fabricate(:vnet_1) }
  let(:vnet_2) { Fabricate(:vnet_2) }

  describe 'basics' do

    let(:tp_simple_underlay) {
      Fabricate(:topology, mode: 'simple_underlay').tap { |topology|
        Fabricate(:topology_network, topology: topology, network: pnet_1)
        Fabricate(:topology_network, topology: topology, network: vnet_1)
      }
    }

    let(:topologies) {
      [ tp_simple_underlay,
        # tp_simple_overlay
      ]
    }

    it 'load on do_initialize' do
      topologies

      # TODO: Make the do_initailized + wait_for_loaded into a helper
      # method, and it should check the return values.
      manager.async.send(:do_initialize)

      topologies.each { |topology|
        manager.wait_for_loaded({ id: topology.id }, 1.0)
      }

      # TODO: Add helper methods for checking internals of managers.
      # topologies = manager.instance_variable_get(:@items)

      # expect(topologys.size).to eq 3

      # TODO: Add helper methods for checking sizes of item things.

      # topologys.values.each do |topology|
      #   expect(topology.networks.size).to eq 3
      # end
    end

  end

end
