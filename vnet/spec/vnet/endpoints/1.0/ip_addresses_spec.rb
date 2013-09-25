# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/ip_addresses" do
  let(:api_suffix)  { "ip_addresses" }
  let(:fabricator)  { :ip_address }
  let(:model_class) { Vnet::Models::IpAddress }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :uuid => "ip-test",
      :ipv4_address => "192.168.2.2",
    }
    required_params = [:ipv4_address]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    accepted_params = { :ipv4_address => "192.168.2.2" }

    include_examples "PUT /:uuid", accepted_params
  end

end
