# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::MacLease do
  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }
  let(:interface) { Fabricate(:interface) }

  let(:mac_lease_params) {
    { interface_id: interface.id,
      mac_address: 12
    }
  }

  describe "create" do
    it "success" do
      # TODO: Add helper method that executes create and verifies
      # model.
      mac_lease = Vnet::NodeApi::MacLease.execute(:create, mac_lease_params)
      expect(mac_lease).to include(mac_lease_params)

      model = Vnet::Models::MacLease[mac_lease[:uuid]]
      expect(model).to be_model_and_include(mac_lease_params)

      expected_params = {
        id: interface.id,
        mac_lease_id: model.id,
        mac_address: 12
      }

      expect(events.size).to eq 1
      expect(events[0]).to be_event(Vnet::Event::INTERFACE_LEASED_MAC_ADDRESS, expected_params)
    end
  end

  describe "destroy" do
    let(:delete_item) { Fabricate(:mac_lease) }
    let(:delete_filter) { delete_item.canonical_uuid }
    let(:delete_events) {
      [ [ Vnet::Event::INTERFACE_RELEASED_MAC_ADDRESS, {
            id: delete_item.interface_id,
            mac_lease_id: delete_item.id
          }]]
    }

    include_examples 'delete item on node_api', :mac_lease
  end
end
