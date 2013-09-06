# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/vifs" do
  let(:api_suffix)  { "vifs" }
  let(:fabricator)  { :vif }
  let(:model_class) { Vnet::Models::Vif }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    before(:all) { use_mock_event_handler }
    let!(:network) { Fabricate(:network) { uuid "nw-testnet" }  }
    let!(:owner) { Fabricate(:datapath) { uuid "dp-owner" } }
    let!(:active) { Fabricate(:datapath) { uuid "dp-active" } }

    accepted_params = {
      :uuid => "vif-test",
      :network_uuid => "nw-testnet",
      :mac_addr => "52:54:00:12:34:70",
      :owner_datapath_uuid => "dp-owner",
      :active_datapath_uuid => "dp-active",
      :ipv4_address => "192.168.3.40",
      :mode => "virtual"
    }
    required_params = [:mac_addr]
    uuid_params = [:network_uuid, :owner_datapath_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params

    it "create vif with ipv4_address" do

      ipv4_address = random_ipv43gt
      mac_addr = random_mac
      network = Fabricate(:network)

      params = {
        mac_addr: mac_addr.to_s,
        network_uuid: network.canonical_uuid,
        ipv4_address: ipv4_address.to_s,
      }

      post "/vifs", params

      expect(last_response).to succeed
      body = JSON.parse(last_response.body)
      expect(body["mac_addr"]).to eq mac_addr.to_i
      expect(body["network_id"]).to eq network.id
      expect(body["ipv4_address"]).to eq ipv4_address.to_i

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1
    end
  end
end
