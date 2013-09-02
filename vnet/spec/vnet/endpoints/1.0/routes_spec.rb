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
    it_behaves_like "a get call with uuid", "routes", "r", :route
  end

  describe "POST /" do
    let!(:vif) { Fabricate(:vif) { uuid "vif-test"}  }
    let!(:route_link) { Fabricate(:route_link) { uuid "rl-test" } }
    accepted_params = {
      :uuid => "r-testrout",
      :display_name => "our test route",
      :vif_uuid => "vif-test",
      :route_link_uuid => "rl-test",
      :ipv4_address => "192.168.10.10",
      :ipv4_prefix => 16,
      :ingress => true,
      :egress => false
    }
    required_params = [:ipv4_address, :route_link_uuid]

    it_behaves_like "a post call", "routes", accepted_params, required_params
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
