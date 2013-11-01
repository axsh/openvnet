# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi::MacLease do
  before do
    use_mock_event_handler
  end

  describe "create" do
    it "success" do
      interface = Fabricate(:interface)
      mac_lease = Vnet::NodeApi::MacLease.execute(
        :create,
        interface: interface,
        mac_address: 1
      )

      model = Vnet::Models::MacLease[mac_lease[:uuid]]
      expect(model.interface_id).to eq interface.id
      expect(model.mac_address).to eq 1

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
      expect(events[0][:event]).to eq Vnet::Event::LEASED_MAC_ADDRESS
      expect(events[0][:options][:target_id]).to eq interface.id
      expect(events[0][:options][:mac_lease_id]).to eq mac_lease[:id]
    end
  end

  describe "destroy" do
    it "success" do
      mac_lease = Fabricate(:mac_lease)

      mac_lease_count = Vnet::Models::MacLease.count
      mac_address_count = Vnet::Models::MacAddress.count

      Vnet::NodeApi::MacLease.execute(:destroy, mac_lease.canonical_uuid)

      expect(Vnet::Models::MacLease.count).to eq mac_lease_count - 1
      expect(Vnet::Models::MacAddress.count).to eq mac_address_count - 1

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
      expect(events[0][:event]).to eq Vnet::Event::RELEASED_MAC_ADDRESS
      expect(events[0][:options][:target_id]).to eq mac_lease.interface_id
      expect(events[0][:options][:mac_lease_id]).to eq mac_lease.id
    end
  end
end
