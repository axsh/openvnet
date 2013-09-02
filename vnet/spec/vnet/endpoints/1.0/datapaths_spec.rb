# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
require_relative 'shared_examples'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/datapaths" do
  describe "GET /" do
    it_behaves_like "a get call without uuid", "datapaths", :datapath
  end

  describe "GET /:uuid" do
    it_behaves_like "a get call with uuid", "datapaths", "dp", :datapath
  end

  describe "POST /" do
    accepted_params = {
      :uuid => "dp-test",
      :display_name => "our test datapath",
      :ipv4_address => "192.168.50.100",
      :is_connected => false,
      :dpid => "0x0000aaaaaaaaaaaa",
      :node_id => "vna45"
    }
    required_params = [:display_name, :dpid, :node_id]

    it_behaves_like "a post call", "datapaths", accepted_params, required_params
  end

  describe "DELETE /:uuid" do
    it_behaves_like "a delete call", "datapaths", "dp", :datapath_1, :Datapath
  end

  describe "PUT /:uuid" do
    request_params = {
      :display_name => "we changed this name",
      :node_id => 'vna45',
      :ipv4_address => "192.168.2.50"
    }
    expected_response = {
      "display_name" => "we changed this name",
      "node_id" => "vna45",
      "ipv4_address" => 3232236082
    }

    it_behaves_like "a put call", "datapaths", "dp", :datapath_1,
      request_params, expected_response
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
