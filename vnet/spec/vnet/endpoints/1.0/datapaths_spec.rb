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

  describe "POST /:uuid/networks/:network_uuid" do
    let!(:network) do
      Fabricate(:network) {
        ipv4_network { sequence(:ipv4_network, IPAddr.new("192.168.1.1").to_i) }
      }
    end
    let!(:datapath) { Fabricate(:datapath_1) }

    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        put "/datapaths/dp-notfound/networks/#{network.canonical_uuid}"
        expect(last_response.status).to eq 404
      end
    end

    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        put "/datapaths/#{datapath.canonical_uuid}/networks/nw-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with a network_uuid that isn't added to this datapath yet" do
      it "should create a new relation in the join table" do
        post "/datapaths/#{datapath.canonical_uuid}/networks/#{network.canonical_uuid}", {
          :broadcast_mac_addr => "02:00:00:cc:00:02"
        }

        expect(last_response).to be_ok
        # p last_response.body.first
        # expect(last_response.body).to eq([
        #   {
        #     "network_uuid" => network.canonical_uuid,
        #     "broadcast_mac_addr" => 2199036624898
        #   }
        # ])

        Vnet::Models::DatapathNetwork.find(
          :datapath_id => datapath.id,
          :network_id => network.id,
          :broadcast_mac_addr => 2199036624898
        ).should_not eq(nil)
      end
    end
  end

end
