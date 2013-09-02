# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
require_relative 'shared_examples'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/networks" do
  describe "GET /" do
    it_behaves_like "a get call without uuid", "networks", :network
  end

  describe "GET /:uuid" do
    it_behaves_like "a get call with uuid", "networks", "nw", :network
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
      it "should return a 400 error" do
        post "/networks", {
          display_name: "network"
        }
        expect(last_response.status).to eq 400
      end
    end
  end

  describe "DELETE /:uuid" do
    it_behaves_like "a delete call", "networks", "nw", :network, :Network
  end

  describe "PUT /:uuid" do
    request_params = {:domain_name => "the.new.domain.name"}
    expected_response = {"domain_name" => "the.new.domain.name"}

    it_behaves_like "a put call", "networks", "nw", :network,
      request_params, expected_response
  end

end
