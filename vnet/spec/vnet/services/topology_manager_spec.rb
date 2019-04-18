# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::Services::TopologyManager do
  let(:node) { double(:node) }
  let(:node_id) { double(:node_id) }

  let(:pass_events) {
    { Vnet::Event::TOPOLOGY_ADDED_NETWORK => manager,
    }
  }

  before(:each) {
    mock_dcell_me_id(node, node_id)
    use_mock_event_handler(pass_events)
  }

  let(:vnet_info) { Vnet::Services::VnetInfo.new }
  let(:manager) { described_class.new(vnet_info) }

  item_names = [
    'item_pnet_1',
    'item_pnet_2',
    'item_vnet_1',
    'item_vnet_2',
  ]

  item_modes = [
    :simple_underlay,
    :simple_underlay,
    :simple_overlay,
    :simple_overlay,
  ]

  item_names.each_with_index { |item_name, item_index|
    let(item_name) {
      item_fabricate_with_events(
        manager,
        item_fabricators[item_index],
        { mode: item_modes[item_index] },
        item_index,
        item_assoc_fabricators)

      # Fabricate(item_fabricators[item_index], mode: item_modes[item_index]).tap { |item_model|
      #   publish_item_created_event(manager, item_model)

      #   item_assoc_fabricate(item_assoc_fabricators, item_model, item_index) { |assoc_fabricator, assoc_model|
      #     publish_item_assoc_added_event(manager, assoc_fabricator, assoc_model)
      #   }
      # }
    }
  }

  let(:item_type) {
    :topology
  }
  let(:item_models) {
    item_names.map { |name| send(name) }
  }

  # TODO: Change this to include item_type+params.
  let(:item_fabricators) {
    item_names.map { |name| item_type }
  }
  let(:item_assoc_counts) {
    { networks: [0, 1, 0, 1],
    }
  }
  let(:item_assoc_fabricators) {
    { topology_network: [
        nil,
        [{ network: pnet_1 }],
        nil,
        [{ network: vnet_2 }]
      ],
    }
  }

  let(:pnet_1) { Fabricate(:pnet_public1) }
  let(:pnet_2) { Fabricate(:pnet_public2) }
  let(:vnet_1) { Fabricate(:vnet_1) }
  let(:vnet_2) { Fabricate(:vnet_2) }

  include_examples 'create items on service manager'
  include_examples 'delete items on service manager', item_names

end
