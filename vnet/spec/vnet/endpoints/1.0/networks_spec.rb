# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/networks" do
  describe "GET /" do
    context "with no networks in the database" do
      it "should return empty json" do
        get "/networks"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body).to be_empty
      end
    end

    context "with 3 networks in the database" do
      (1..3).each do |i|
        let!("nw#{i}".to_sym) {
          Fabricate(:network) do
            ipv4_network { sequence(:ipv4_network, IPAddr.new("192.168.1.1").to_i) }
          end
        }
      end

      it "should return 3 networks" do
        get "/networks"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body.size).to eq 3
      end
    end
  end

  describe "GET /:uuid" do
    context "with a non existing uuid" do
      it "should return 404 error" do
        get "/networks/nw-notfound"
        expect(last_response).to be_not_found
      end
    end

    context "with an existing uuid" do
      let!(:network) { Fabricate(:network) }

      it "should return a network" do
        get "/networks/#{network.canonical_uuid}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq network.canonical_uuid
      end
    end
  end

  describe "POST /" do
    context "without the uuid parameter" do
      it "should create a network" do
        params = {
          display_name: "network",
          ipv4_network: "192.168.10.1",
          ipv4_prefix: 24,
        }
        post "/networks", params

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["display_name"]).to eq "network"
        expect(body["ipv4_network"]).to eq IPAddr.new("192.168.10.1").to_i
        expect(body["ipv4_prefix"]).to eq 24
      end
    end

    context "with the uuid parameter" do
      it "should create a network with the given uuid" do
        post "/networks", {
          display_name: "network",
          ipv4_network: "192.168.10.1",
          uuid: "nw-testnw"
        }

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq "nw-testnw"
      end
    end

    context "with a uuid parameter with a faulty syntax" do
      it "should return a 400 error" do
        post "/networks", { :uuid => "this_aint_no_uuid" }
        expect(last_response.status).to eq 400
      end
    end

    context "without the 'display_name' parameter" do
      it "should return a 400 error" do
        post "/networks", {
          :ipv4_network => "192.168.10.1"
        }
        expect(last_response.status).to eq 400
      end
    end

    context "without the 'ipv4_network' parameter" do
      it "should return a 500 error" do
        post "/networks", {
          display_name: "network"
        }
      end
    end
  end

  describe "DELETE /:uuid" do
    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        delete "/networks/nw-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing uuid" do
      let!(:network) { Fabricate(:network) }
      it "should delete the network" do
        delete "/networks/#{network.canonical_uuid}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq network.canonical_uuid
      end
    end
  end

  describe "PUT /:uuid" do
    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        put "/networks/nw-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing uuid" do
      let!(:network) { Fabricate(:network) }
      it "should update the network" do
        put "/networks/#{network.canonical_uuid}", :domain_name => "aaa.#{network.domain_name}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq network.canonical_uuid
        expect(body["domain_name"]).not_to eq network.domain_name
      end
    end
  end

end
