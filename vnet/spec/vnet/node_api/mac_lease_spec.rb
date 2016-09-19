# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi::MacLease do
  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }

  let(:interface) { Fabricate(:interface) }
  let(:mac_lease_empty) { Fabricate(:mac_lease) }

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
    it "success" do
      mac_lease_empty

      # TODO: Add helper method for this.
      mac_lease_count = Vnet::Models::MacLease.count
      mac_address_count = Vnet::Models::MacAddress.count

      Vnet::NodeApi::MacLease.execute(:destroy, mac_lease_empty.canonical_uuid)

      expect(Vnet::Models::MacLease.count).to eq mac_lease_count - 1
      expect(Vnet::Models::MacAddress.count).to eq mac_address_count - 1

      expected_params = {
        id: mac_lease_empty.interface_id,
        mac_lease_id: mac_lease_empty.id
      }

      expect(events.size).to eq 1
      expect(events[0]).to be_event(Vnet::Event::INTERFACE_RELEASED_MAC_ADDRESS, expected_params)
    end
  end
end
