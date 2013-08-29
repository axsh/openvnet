# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/datapaths" do
  describe "GET /" do
    context "with no datapaths in the database" do
      it "should return empty json" do
        get "/datapaths"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body).to be_empty
      end
    end

    context "with 3 datapaths in the database" do
      before(:each) do
        Fabricate(:datapath_1)
        Fabricate(:datapath_2)
        Fabricate(:datapath_3)
      end

      it "should return 3 datapaths" do
        get "/datapaths"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body.size).to eq 3
      end
    end
  end

  describe "GET /:uuid" do
    context "with a non existing uuid" do
      it "should return 404 error" do
        get "/datapaths/dp-notfound"
        expect(last_response).to be_not_found
      end
    end

    context "with an existing uuid" do
      let!(:datapath) { Fabricate(:datapath_1) }

      it "should return a datapath" do
        get "/datapaths/#{datapath.canonical_uuid}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq datapath.canonical_uuid
      end
    end
  end

  describe "POST /" do
    context "without the uuid parameter" do
      it "should create a datapath" do
        params = {
          display_name: "datapath",
          dpid: "0x0000aaaaaaaaaaaa",
          node_id: "vna1"
        }
        post "/datapaths", params

        body = JSON.parse(last_response.body)
        expect(body["display_name"]).to eq "datapath"
        expect(body["dpid"]).to eq "0x0000aaaaaaaaaaaa"
        expect(body["node_id"]).to eq "vna1"
      end
    end

    context "with the uuid parameter" do
      it "should create a datapath with the given uuid" do
        post "/datapaths", {
          display_name: "datapath",
          dpid: "0x0000aaaaaaaaaaaa",
          node_id: "vna1",
          uuid: "dp-testdp"
        }

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq "dp-testdp"
      end
    end

    context "with a uuid parameter with a faulty syntax" do
      it "should return a 400 error" do
        post "/datapaths", { :uuid => "this_aint_no_uuid" }
        expect(last_response.status).to eq 400
      end
    end

    context "without the 'display_name' parameter" do
      it "should return a 400 error" do
        post "/datapaths", {
          :ipv4_datapath => "192.168.10.1"
        }
        expect(last_response.status).to eq 400
      end
    end

    context "without the 'ipv4_datapath' parameter" do
      it "should return a 500 error" do
        post "/datapaths", {
          display_name: "datapath"
        }
      end
    end
  end

  describe "DELETE /:uuid" do
    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        delete "/datapaths/dp-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing uuid" do
      let!(:datapath) { Fabricate(:datapath_1) }
      it "should delete the datapath" do
        delete "/datapaths/#{datapath.canonical_uuid}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq datapath.canonical_uuid

        Vnet::Models::Datapath[datapath.canonical_uuid].should eq(nil)
      end
    end
  end

  describe "PUT /:uuid" do
    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        put "/datapaths/dp-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing uuid" do
      let!(:datapath) { Fabricate(:datapath_1) }
      it "should update the datapath" do
        put "/datapaths/#{datapath.canonical_uuid}", {
          :display_name => "we changed this name",
          :node_id => 'vna45'
        }

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq datapath.canonical_uuid
        expect(body["display_name"]).to eq "we changed this name"
        expect(body["node_id"]).to eq "vna45"
      end
    end
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
