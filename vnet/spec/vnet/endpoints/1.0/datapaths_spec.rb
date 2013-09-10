# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/datapaths" do
  let(:api_suffix)  { "datapaths" }
  let(:fabricator)  { :datapath }
  let(:model_class) { Vnet::Models::Datapath }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:dc_segment) { Fabricate(:dc_segment) { uuid "ds-segment" } }
    accepted_params = {
      :uuid => "dp-test",
      :display_name => "our test datapath",
      :ipv4_address => "192.168.50.100",
      :is_connected => false,
      :dpid => "0x0000aaaaaaaaaaaa",
      :node_id => "vna45",
      :dc_segment_uuid => "ds-segment"
    }

    required_params = [:display_name, :dpid, :node_id]
    uuid_params = [:uuid, :dc_segment_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    let!(:new_dc_segment) { Fabricate(:dc_segment) { uuid "ds-newseg" } }
    accepted_params = {
      :display_name => "we changed this name",
      :ipv4_address => "192.168.2.50",
      :dpid => "0x0000abcdefabcdef",
      :dc_segment_uuid => "ds-newseg",
      :node_id => 'vna45'
    }
    uuid_params = [:dc_segment_uuid]

    include_examples "PUT /:uuid", accepted_params, uuid_params
  end

  describe "Many to many relation calls for networks" do
    let(:relation_fabricator) { :network }

    include_examples "many_to_many_relation", "networks",
      {:broadcast_mac_addr => "02:00:00:cc:00:02"}
  end

  describe "Many to many relation calls for route links" do
    let(:relation_fabricator) { :route_link }

    include_examples "many_to_many_relation", "route_links",
      {:link_mac_address => "52:54:00:12:34:30" }
  end

end
