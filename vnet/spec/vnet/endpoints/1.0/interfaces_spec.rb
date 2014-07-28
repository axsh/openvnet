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

  #
  # Base:
  #

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:network) { Fabricate(:network) { uuid "nw-testnet" }  }
    let!(:owner) { Fabricate(:datapath) { uuid "dp-owner" } }
    let!(:active) { Fabricate(:datapath) { uuid "dp-active" } }

    expected_response = {
      :uuid => "if-test",
      :network_uuid => "nw-testnet",
      :ipv4_address => "192.168.1.10",
      :ingress_filtering_enabled => true,
      :mac_address => "11:11:11:11:11:11",
      :mode => "simulated"
    }
    accepted_params = expected_response.merge(owner_datapath_uuid: "dp-owner")
    required_params = []
    uuid_params = [:network_uuid, :owner_datapath_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params, expected_response

    context "With a faulty mac address" do
      let(:request_params) { { mac_address: "i am not a mac address" } }

      it_should_return_error(400, "ArgumentError")
    end

    context "With a faulty ipv4 address" do
      let(:request_params) { { ipv4_address: "i am not an ip address" } }

      it_should_return_error(400, "ArgumentError")
    end

    describe "event handler" do
      let(:request_params) { {} }

      it "handles a single event" do
        expect(last_response).to succeed
        expect(MockEventHandler.handled_events.size).to eq 2
      end
    end
  end

  describe "PUT /:uuid" do
    let!(:owner) { Fabricate(:datapath) { uuid "dp-new" } }

    accepted_params = {
      :display_name => "updated interface",
      :ingress_filtering_enabled => true,
      # :owner_datapath_uuid => "dp-new",
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

  #
  # Ports:
  #

  # TODO: Write shared example for this:

  # describe "POST /:uuid/ports" do
  #   let!(:owner) { Fabricate(:datapath) { uuid "dp-owner" } }
  #   #let!(:interface) { Fabricate(:interface) { uuid "if-test" } }

  #   expected_response = {
  #     interface_uuid: 'if-test',
  #     datapath_uuid: 'dp-owner',
  #     port_name: 'vif-foo',
  #     singular: 1
  #   }

  #   accepted_params = expected_response #.merge( datapath_uuid: "dp-owner")
  #   required_params = []
  #   uuid_params = [:datapath_uuid]

  #   include_examples "POST /:uuid/ports", accepted_params, required_params, uuid_params, expected_response
  # end

  #
  # Security groups:
  #

  describe "Many to many relation calls for security groups" do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :security_group }

    let!(:interface) { Fabricate(:interface) { uuid "if-test" } }

    include_examples "many_to_many_relation", "security_groups", {}
  end

end
