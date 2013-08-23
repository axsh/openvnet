# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/networks" do
  describe "GET /" do
    it "should return empty json" do
      get "/networks"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body).to be_empty
    end

    it "should return 3 networks" do
      3.times.inject([]) do |array|
        array << Fabricate(:network) do
          ipv4_network { sequence(:ipv4_network, IPAddr.new("192.168.1.1").to_i) }
        end
      end

      get "/networks"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body.size).to eq 3
    end
  end

  describe "GET /:uuid" do
    it "should return 404 error" do
      get "/networks/nw-notfound"
      expect(last_response).to be_not_found
    end

    it "should return a network" do
      network = Fabricate(:network)

      get "/networks/#{network.canonical_uuid}"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body["uuid"]).to eq network.canonical_uuid
    end
  end

  describe "POST /" do
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

  describe "DELETE /:uuid" do
    it "should return 404 error" do
      delete "/networks/nw-notfound"
      # TODO should be 404
      #expect(last_response.status).to eq 404
      expect(last_response.status).to eq 500
    end

    it "should delete a network" do
      network = Fabricate(:network)

      delete "/networks/#{network.canonical_uuid}"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body["uuid"]).to eq network.canonical_uuid
    end
  end

  describe "PUT /:uuid" do
    it "should return 404 error" do
      put "/networks/nw-notfound"
      # TODO should be 404
      #expect(last_response.status).to eq 404
      expect(last_response.status).to eq 500
    end

    it "should update a network" do
      network = Fabricate(:network)

      put "/networks/#{network.canonical_uuid}", :domain_name => "aaa.#{network.domain_name}"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body["uuid"]).to eq network.canonical_uuid
      expect(body["domain_name"]).not_to eq network.domain_name
    end
  end

  describe "PUT /:uuid/attach_interface" do
    it "should return 404 error" do
      put "/networks/nw-notfound/attach_interface"
      # TODO should be 404
      #expect(last_response.status).to eq 404
      expect(last_response.status).to eq 500
    end

    it "should return 404 error" do
      network = Fabricate(:network)
      put "/networks/#{network.canonical_uuid}/attach_interface", :interface_uuid => "interface-notfound"
      # TODO should be 404
      #expect(last_response.status).to eq 404
      expect(last_response.status).to eq 500
    end

    it "should attach interface to network" do
      network = Fabricate(:network)
      interface = Fabricate(:iface)
      expect(network.interfaces).to be_empty

      put "/networks/#{network.canonical_uuid}/attach_interface", :interface_uuid => interface.canonical_uuid

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body["uuid"]).to eq network.canonical_uuid

      network.reload

      expect(network.interfaces.size).to eq 1
      expect(network.interfaces.first.uuid).to eq interface.uuid
    end
  end

  describe "PUT /:uuid/detach_interface" do
    it "should return 404 error" do
      put "/networks/nw-notfound/detach_interface"
      # TODO should be 404
      #expect(last_response.status).to eq 404
      expect(last_response.status).to eq 500
    end

    it "should return 404 error" do
      network = Fabricate(:network)
      put "/networks/#{network.canonical_uuid}/detach_interface", :interface_uuid => "interface-notfound"
      # TODO should be 404
      #expect(last_response.status).to eq 404
      expect(last_response.status).to eq 500
    end

    it "should detach interface to network" do
      interface = Fabricate(:iface) do
        network
      end
      network = interface.network
      expect(network.interfaces.size).to eq 1

      put "/networks/#{network.canonical_uuid}/detach_interface", :interface_uuid => interface.canonical_uuid

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body["uuid"]).to eq network.canonical_uuid

      network.reload
      expect(network.interfaces).to be_empty
    end
  end
end
