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

    include_examples "POST /", accepted_params, required_params
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

    include_examples "PUT /", accepted_params
  end

end
