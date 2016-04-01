# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/datapaths" do
  before(:each) { use_mock_event_handler }
  let(:api_suffix)  { "datapaths" }
  let(:fabricator)  { :datapath }
  let(:model_class) { Vnet::Models::Datapath }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :uuid => "dp-test",
      :display_name => "our test datapath",
      :is_connected => false,
      :dpid => "0x0000aaaaaaaaaaaa",
      :node_id => "vna45",
    }

    required_params = [:display_name, :dpid, :node_id]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    accepted_params = {
      :display_name => "we changed this name",
      :dpid => "0x0000abcdefabcdef",
      :node_id => 'vna45'
    }
    uuid_params = []

    include_examples "PUT /:uuid", accepted_params, uuid_params
  end

  describe "Many to many relation calls for networks" do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :network }

    let!(:interface) { Fabricate(:interface_w_ip_lease) { uuid "if-test" } }

    include_examples "many_to_many_relation", "networks", {
      :mac_address => "02:00:00:cc:00:02",
      :interface_uuid => 'if-test'
    }
  end

  describe "Many to many relation calls for route links" do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :route_link }

    let!(:interface) { Fabricate(:interface_w_ip_lease) { uuid "if-test" } }

    include_examples "many_to_many_relation", "route_links", {
      :mac_address => "02:00:00:cc:00:02",
      :interface_uuid => 'if-test'
    }
  end

end
