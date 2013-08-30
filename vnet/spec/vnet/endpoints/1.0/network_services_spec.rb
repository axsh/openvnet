# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/network_services" do
  describe "GET /" do
    context "with no network_services in the database" do
      it "should return empty json" do
        get "/network_services"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body).to be_empty
      end
    end

    context "with 3 network_services in the database" do
      before(:each) do
        3.times { Fabricate(:network_service) }
      end

      it "should return 3 network_services" do
        get "/network_services"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body.size).to eq 3
      end
    end
  end

  describe "GET /:uuid" do
    context "with a non existing uuid" do
      it "should return 404 error" do
        get "/network_services/ns-notfound"
        expect(last_response).to be_not_found
      end
    end

    context "with an existing uuid" do
      let!(:network_service) { Fabricate(:network_service) }

      it "should return a network_service" do
        get "/network_services/#{network_service.canonical_uuid}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq network_service.canonical_uuid
      end
    end
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
    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        delete "/network_services/ns-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing uuid" do
      let!(:network_service) { Fabricate(:network_service) }
      it "should delete the network_service" do
        delete "/network_services/#{network_service.canonical_uuid}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body.first).to eq network_service.canonical_uuid

        Vnet::Models::NetworkService[network_service.canonical_uuid].should eq(nil)
      end
    end
  end

  describe "PUT /:uuid" do
    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        put "/network_services/ns-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing uuid" do
      let!(:network_service) { Fabricate(:network_service) }
      it "should update the network_service" do
        put "/network_services/#{network_service.canonical_uuid}",
          :display_name => "new display name"

        puts last_response.errors
        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body["uuid"]).to eq network_service.canonical_uuid
        expect(body["display_name"]).to eq "new display name"
      end
    end
  end

end
