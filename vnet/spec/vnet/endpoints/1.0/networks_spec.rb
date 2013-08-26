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
        post "/networks", { :uuid => "nw-testnw" }

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
  end

  describe "DELETE /:uuid" do
    context "with a nonexistant uuid" do
      it "should return 404 error" do
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
      it "should return 404 error" do
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

  describe "PUT /:uuid/attach_vif" do
    context "with a nonexistant network uuid" do
      it "should return 404 error" do
        put "/networks/nw-notfound/attach_vif"
        expect(last_response.status).to eq 404
      end
    end

    context "with a nonexistant vif uuid" do
      let!(:network) { Fabricate(:network) }
      it "should return 404 error" do
        put "/networks/#{network.canonical_uuid}/attach_vif", :vif_uuid => "vif-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing network uuid and an existing vif uuid" do
      let!(:network) { Fabricate(:network) }
      let!(:vif) { Fabricate(:vif) }
      it "should attach vif to network" do
        expect(network.vifs).to be_empty

        put "/networks/#{network.canonical_uuid}/attach_vif", :vif_uuid => vif.canonical_uuid

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq network.canonical_uuid

        network.reload

        expect(network.vifs.size).to eq 1
        expect(network.vifs.first.uuid).to eq vif.uuid
      end
    end
  end

  describe "PUT /:uuid/detach_vif" do
    context "with a nonexistant network uuid" do
      it "should return 404 error" do
        put "/networks/nw-notfound/detach_vif"
        expect(last_response.status).to eq 404
      end
    end

    context "with a nonexistant vif uuid" do
      let!(:network) { Fabricate(:network) }
      it "should return 404 error" do
        put "/networks/#{network.canonical_uuid}/detach_vif", :vif_uuid => "vif-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing network uuid and an existing vif uuid" do
      let!(:vif) { Fabricate(:vif) {network} }
      let(:network) { vif.network }

      it "should detach vif from network" do
        expect(network.vifs.size).to eq 1

        put "/networks/#{network.canonical_uuid}/detach_vif", :vif_uuid => vif.canonical_uuid

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq network.canonical_uuid

        network.reload
        expect(network.vifs).to be_empty
      end
    end
  end
end
