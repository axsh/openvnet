# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
require_relative 'shared_examples'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/routes" do
  describe "GET /" do
    it_behaves_like "a get call without uuid", "routes", :route
  end

  describe "GET /:uuid" do
    context "with a non existing uuid" do
      it "should return 404 error" do
        get "/routes/r-notfound"
        expect(last_response).to be_not_found
      end
    end

    context "with an existing uuid" do
      let!(:route) { Fabricate(:route) }

      it "should return a route" do
        get "/routes/#{route.canonical_uuid}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq route.canonical_uuid
      end
    end
  end

  describe "POST /" do
    let (:route_link) { Fabricate(:route_link) }
    context "without the uuid parameter" do
      it "should create a route" do
        params = {
          :ipv4_address => "10.0.0.1",
          :route_link_uuid => route_link.canonical_uuid
        }
        post "/routes", params

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["ipv4_address"]).to eq 167772161
      end
    end

    context "with the uuid parameter" do
      it "should create a route with the given uuid" do
        post "/routes", {
          ipv4_address: "10.0.0.1",
          uuid: "r-testrout",
          route_link_uuid: route_link.canonical_uuid
        }

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq "r-testrout"
        expect(body["ipv4_address"]).to eq 167772161
      end
    end

    context "with a uuid parameter with a faulty syntax" do
      it "should return a 400 error" do
        post "/routes", { :uuid => "this_aint_no_uuid" }
        expect(last_response.status).to eq 400
      end
    end

    context "without the 'ipv4_address' parameter" do
      it "should return a 400 error" do
        post "/routes"
        expect(last_response.status).to eq 400
      end
    end
  end

  describe "DELETE /:uuid" do
    it_behaves_like "a delete call", "routes", "r", :route, :Route
  end

  describe "PUT /:uuid" do
    request_params = { :ipv4_address => "192.168.3.50", :ipv4_prefix => 16 }
    expected_response = {
      "ipv4_address" => 3232236338,
      "ipv4_prefix" => 16
    }
    it_behaves_like "a put call", "routes", "r", :route, request_params, expected_response
  end

end
