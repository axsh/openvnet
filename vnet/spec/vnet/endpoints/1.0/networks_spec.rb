# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/networks" do
  let(:api_suffix)  { "networks" }
  let(:fabricator)  { :network }
  let(:model_class) { Vnet::Models::Network }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "DELETE /:uuid" do
    it "returns DependencyExists(400) error" do
      network = Fabricate(:network)
      ip_address = Fabricate(:ip_address, network: network)

      delete "/networks/#{network.canonical_uuid}"

      expect(last_response.status).to be 400
      expect(last_response.body).to match /DeleteRestrictionError/
    end
  end

  describe "POST /" do
    accepted_params = {
      :uuid => "nw-test",
      :display_name => "our test network",
      :ipv4_network => "192.168.2.0",
      :ipv4_prefix => 24,
      :domain_name => "vdc.test.domain",
      :network_mode => "virtual",
      :editable => false
    }
    required_params = [:display_name, :ipv4_network]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    accepted_params = {
      :display_name => "our new name for the test network",
      :ipv4_network => "10.0.0.2",
      :ipv4_prefix => 8,
      :domain_name => "new.vdc.test.domain",
      :network_mode => "physical",
      :editable => true
    }

    include_examples "PUT /:uuid", accepted_params
  end

  describe "One to many relation calls for dhcp_ranges" do
    let(:relation_fabricator) { :dhcp_range }

    include_examples "one_to_many_relation", "dhcp_ranges", {
      :uuid => "dr-newrange",
      :range_begin => "192.168.2.2",
      :range_end => "192.168.2.100"
    }
  end

end
