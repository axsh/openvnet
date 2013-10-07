# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/interfaces" do
  let(:api_suffix)  { "interfaces" }
  let(:fabricator)  { :interface }
  let(:model_class) { Vnet::Models::Interface }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    before(:all) { use_mock_event_handler }
    let!(:network) { Fabricate(:network) { uuid "nw-testnet" }  }
    let!(:owner) { Fabricate(:datapath) { uuid "dp-owner" } }
    let!(:active) { Fabricate(:datapath) { uuid "dp-active" } }

    accepted_params = {
      :uuid => "if-test",
      :network_uuid => "nw-testnet",
      :ipv4_address => "192.168.1.10",
      :mac_address => "11:11:11:11:11:11",
      :owner_datapath_uuid => "dp-owner",
      :mode => "simulated"
    }
    required_params = []
    uuid_params = [:network_uuid, :owner_datapath_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params

    describe "event handler" do
      let(:request_params) { {} }

      it "handles a single event" do
        expect(last_response).to succeed
        MockEventHandler.handled_events.size.should eq 1
      end
    end
  end

  describe "PUT /:uuid" do
    before(:all) { use_mock_event_handler }
    let!(:network) { Fabricate(:network) { uuid "nw-testnet" }  }
    let!(:owner) { Fabricate(:datapath) { uuid "dp-owner" } }
    let!(:active) { Fabricate(:datapath) { uuid "dp-active" } }

    accepted_params = {
      :network_uuid => "nw-testnet",
      :ipv4_address => "192.168.2.10",
      :mac_address => "22:22:22:22:22:22",
      :owner_datapath_uuid => "dp-owner",
      :mode => "simulated"
    }

    include_examples "PUT /:uuid", accepted_params
  end
end
