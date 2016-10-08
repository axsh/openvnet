# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::Services::IpRetentionContainerManager do
  let(:vnet_info) { Vnet::Services::VnetInfo.new }
  let(:manager) { described_class.new(vnet_info) }

  let(:item_name) { :ip_retention_container }

  item_names = (1..3).map { |index| "item_#{index}" }

  item_names.each_with_index { |name, index|
    let(name) {
      Fabricate(item_name).tap { |item_model|
        (index).times {
          Fabricate(:ip_retention, item_name => item_model)
        }

        publish_item_created_event(manager, item_model)
      }
    }
  }

  let(:item_models) {
    (1..3).map { |index| send("item_#{index}") }
  }

  let(:item_assoc_counts) {
    { leased_ip_retentions: [0, 1, 2],
    }
  }

  describe "create items" do
    include_examples 'create items on service manager'
  end

  describe "delete items from #{item_names.join(', ')}" do
    include_examples 'delete items on service manager', item_names
  end

end
