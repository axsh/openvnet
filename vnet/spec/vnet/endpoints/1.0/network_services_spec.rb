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
    let!(:vif) { Fabricate(:vif) { uuid "vif-test"}  }
    accepted_params = {
      :uuid => "ns-test",
      :vif_uuid => "vif-test",
      :display_name => "our test network service",
      :incoming_port => 40,
      :outgoing_port => 100
    }
    required_params = [:display_name]

    it_behaves_like "a post call", "network_services", accepted_params, required_params
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
