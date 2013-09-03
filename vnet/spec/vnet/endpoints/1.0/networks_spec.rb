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
    let (:accepted_params) do
      {
        :uuid => "nw-test",
        :display_name => "our test network",
        :ipv4_network => "192.168.2.0",
        :ipv4_prefix => 24,
        :domain_name => "vdc.test.domain",
        :network_mode => "virtual",
        :editable => false
      }
    end
    required_params = [:display_name, :ipv4_network]
    uuid_params = [:uuid]

    include_examples "POST /", required_params, uuid_params
  end

  describe "PUT /:uuid" do
    let(:accepted_params) do
      {
        :display_name => "our new name for the test network",
        :ipv4_network => "10.0.0.2",
        :ipv4_prefix => 8,
        :domain_name => "new.vdc.test.domain",
        :network_mode => "physical",
        :editable => true
      }
    end

    include_examples "PUT /:uuid"
  end

end
