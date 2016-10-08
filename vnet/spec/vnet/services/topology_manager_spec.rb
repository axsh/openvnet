# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::Services::TopologyManager do
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

  item_names.each_with_index { |item_name, index|
    let(item_name) {
      Fabricate(item_fabricators[index], mode: item_modes[index]).tap { |item_model|
        item_assoc_fabricators.each { |assoc_fabricator, assoc_params|
          Fabricate(assoc_fabricator, assoc_params[index].merge(topology: item_model)) if assoc_params[index]
        }

        publish_item_created_event(manager, item_model)
      }
    }
  }

  # TODO: Try to add a shared_examples

  let(:item_type) { :topology }

  let(:item_models) {
    item_names.map { |name| send(name) }
  }

  let(:item_fabricators) {
    item_names.map { |name| item_type }
  }

  let(:item_assoc_counts) {
    { networks: [0, 1, 0, 0],
    }
  }

  let(:item_assoc_fabricators) {
    { topology_network: [nil, { network: pnet_1 }, nil, nil],
    }
  }

  let(:pnet_1) { Fabricate(:pnet_public1) }
  let(:pnet_2) { Fabricate(:pnet_public2) }
  let(:vnet_1) { Fabricate(:vnet_1) }
  let(:vnet_2) { Fabricate(:vnet_2) }

  describe "create items" do
    include_examples 'create items on service manager'
  end

  describe "delete items from #{item_names.join(', ')}" do
    include_examples 'delete items on service manager', item_names

    # it "test foo_bar" do
    # end
  end

end
