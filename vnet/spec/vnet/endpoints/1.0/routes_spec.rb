# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
require_relative 'shared_examples'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/routes" do
  describe "GET /" do
    context "with no routes in the database" do
      it "should return empty json" do
        get "/routes"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body).to be_empty
      end
    end

    context "with 3 routes in the database" do
      before(:each) do
        3.times { Fabricate(:route) }
      end

      it "should return 3 routes" do
        get "/routes"

        puts last_response.errors
        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body.size).to eq 3
      end
    end
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
    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        put "/routes/r-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing uuid" do
      let!(:route) { Fabricate(:route) }
      it "should update the route" do
        put "/routes/#{route.canonical_uuid}", {
          :ipv4_address => "192.168.3.50",
          :ipv4_prefix => 16
        }

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq route.canonical_uuid
        expect(body["ipv4_address"]).to eq 3232236338
        expect(body["ipv4_prefix"]).to eq 16
      end
    end
  end

end
