# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
require_relative 'shared_examples'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/network_services" do
  describe "GET /" do
    it_behaves_like "a get call without uuid", "network_services", :network_service
  end

  describe "GET /:uuid" do
    it_behaves_like "a get call with uuid", "network_services", "ns", :network_service
  end

  describe "POST /" do
    context "without the uuid parameter" do
      it "should create a network_service" do
        params = {
          display_name: "network_service",
        }
        post "/network_services", params

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["display_name"]).to eq "network_service"
      end
    end

    context "with the uuid parameter" do
      it "should create a network_service with the given uuid" do
        post "/network_services", {
          display_name: "network_service",
          uuid: "ns-testns"
        }

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq "ns-testns"
        expect(body["display_name"]).to eq "network_service"
      end
    end

    context "with a uuid parameter with a faulty syntax" do
      it "should return a 400 error" do
        post "/network_services", { :uuid => "this_aint_no_uuid" }
        expect(last_response.status).to eq 400
      end
    end

    context "without the 'display_name' parameter" do
      it "should return a 400 error" do
        post "/network_services"
        expect(last_response.status).to eq 400
      end
    end
  end

  describe "DELETE /:uuid" do
    it_behaves_like "a delete call", "network_services", "ns",
      :network_service, :NetworkService
  end

  describe "PUT /:uuid" do
    request_params = {:display_name => "new display name"}
    expected_response = {"display_name" => "new display name"}

    it_behaves_like "a put call", "network_services", "ns", :network_service,
      request_params, expected_response
  end

end
