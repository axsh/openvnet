# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi::IpLease do
  before do
    use_mock_event_handler
  end

  describe "create" do
    it "success" do
      network = Fabricate(:network)
      ipv4_address = random_ipv4_i
      interface = Fabricate(:interface)
      mac_lease = Fabricate(:mac_lease, interface: interface)

      ip_lease = Vnet::NodeApi::IpLease.execute(
        :create,
        mac_lease: mac_lease,
        network_id: network.id,
        ipv4_address: ipv4_address
      )

      model = Vnet::Models::IpLease[ip_lease[:uuid]]
      expect(model.ip_address.ipv4_address).to eq ipv4_address
      expect(model.network_id).to eq network.id
      expect(ip_lease[:ip_address_id]).to eq model.ip_address_id
      expect(ip_lease[:interface_id]).to eq interface.id

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
      expect(events[0][:event]).to eq Vnet::Event::LeasedIpv4Address
      expect(events[0][:options][:target_id]).to eq interface.id
      expect(events[0][:options][:ip_lease_id]).to eq ip_lease[:id]
    end
  end

  describe "destroy" do
    it "success" do
      ip_lease = Fabricate(:ip_lease)

      ip_lease_count = Vnet::Models::IpLease.count
      ip_address_count = Vnet::Models::IpAddress.count

      Vnet::NodeApi::IpLease.destroy(ip_lease.canonical_uuid)

      expect(Vnet::Models::IpLease.count).to eq ip_lease_count - 1
      expect(Vnet::Models::IpAddress.count).to eq ip_address_count - 1

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
      expect(events[0][:event]).to eq Vnet::Event::ReleasedIpv4Address
      expect(events[0][:options][:target_id]).to eq ip_lease.interface_id
      expect(events[0][:options][:ip_lease_id]).to eq ip_lease.id
    end
  end
end
