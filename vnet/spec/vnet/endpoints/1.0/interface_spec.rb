# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/ifaces" do
  describe "POST /" do
    it "create iface with ipv4_address" do
      use_mock_event_handler

      ipv4_address = random_ipv4
      mac_addr = random_mac
      network = Fabricate(:network)

      params = {
        name: 'vif-test',
        mode: 'virtual',
        #network_id: network.canonical_uuid,
      }

      post "/ifaces", params

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      #expect(body["mac_addr"]).to eq mac_addr.to_i
      #expect(body["network_id"]).to eq network.id
      #expect(body["ipv4_address"]).to eq ipv4_address.to_i
      expect(body["mode"]).to eq "virtual"

      # events = MockEventHandler.handled_events
      # expect(events.size).to eq 1
    end
  end
end
