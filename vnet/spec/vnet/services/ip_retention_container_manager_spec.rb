# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::Services::IpRetentionContainerManager do
  let(:vnet_info) { Vnet::Services::VnetInfo.new }
  let(:manager) { described_class.new(vnet_info) }

  let(:node) { double(:node) }
  let(:node_id) { double(:node_id) }

  before(:each) {
    use_mock_event_handler

    mock_dcell_me_id(node, node_id)
  }

  item_names = (1..3).map { |index| "item_#{index}" }

  item_names.each_with_index { |item_name, index|
    let(item_name) {
      Fabricate(item_fabricators[index]).tap { |item_model|
        (index).times {
          Fabricate(:ip_retention, item_type => item_model)
        }

        publish_item_created_event(manager, item_model)
      }
    }
  }

  let(:item_type) { :ip_retention_container }
  let(:item_models) { item_names.map { |name| send(name) } }
  let(:item_fabricators) { item_names.map { |name| item_type } }
  let(:item_assoc_counts) { { leased_ip_retentions: [0, 1, 2], } }

  include_examples 'create items on service manager'
  include_examples 'delete items on service manager', item_names

end
