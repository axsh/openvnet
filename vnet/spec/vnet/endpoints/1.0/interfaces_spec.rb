# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/interfaces" do
  before(:each) { use_mock_event_handler }
  let(:api_suffix)  { "interfaces" }
  let(:fabricator)  { :interface }
  let(:model_class) { Vnet::Models::Interface }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
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
        expect(MockEventHandler.handled_events.size).to eq 1
      end
    end
  end

  describe "PUT /:uuid" do
    let!(:owner) { Fabricate(:datapath) { uuid "dp-new" } }

    accepted_params = {
      :display_name => "updated interface",
      :owner_datapath_uuid => "dp-new",
    }

    include_examples "PUT /:uuid", accepted_params

    describe "event handler" do
      let(:request_params) { {} }

      it "handles a single event" do
        expect(last_response).to succeed
        expect(MockEventHandler.handled_events.size).to eq 1
      end
    end
  end
end
