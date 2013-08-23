# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::NodeApi::Interface do
  before do
    use_mock_event_handler
  end

  describe "create" do
    it "success" do
      mac_addr = random_mac_i
      network = Fabricate(:network)
      ipv4_address = random_ipv4_i

      iface = Vnet::NodeApi::Interface.create(
#        mac_addr: mac_addr,
        network_id: network.id,
#        ipv4_address: ipv4_address
      )

      expect(iface[:network_id]).to eq network.id
#      expect(iface[:mac_addr]).to eq mac_addr
#      expect(iface[:ipv4_address]).to eq ipv4_address

#      events = MockEventHandler.handled_events
#      expect(events.size).to eq 1
#      expect(events[0][:event]).to eq "network/iface_added"
#      expect(events[0][:options][:network_id]).to eq network.id
#      expect(events[0][:options][:iface_id]).to eq iface[:id]
    end
  end
end
