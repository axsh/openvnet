# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi::Interface do
  before do
    use_mock_event_handler
  end

  describe "create" do
    it "success" do
      mac_address = random_mac_i
      network = Fabricate(:network)
      ipv4_address = random_ipv4_i

      interface = Vnet::NodeApi::Interface.create(
        mac_address: mac_address,
        network_id: network.id,
        ipv4_address: ipv4_address
      )

      expect(interface[:network_id]).to eq network.id
      expect(interface[:mac_address]).to eq mac_address
      expect(interface[:ipv4_address]).to eq ipv4_address

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
      expect(events[0][:event]).to eq :leased_ipv4_address
      expect(events[0][:options][:interface_id]).to eq interface[:id]
      #expect(events[0][:options][:ip_lease_id]).to eq interface[:ip_lease_id]
      #expect(events[0][:options][:mac_lease_id]).to eq interface[:mac_lease_id]
    end
  end
end
