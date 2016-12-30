# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/route_links" do
  before(:each) { use_mock_event_handler }

  let(:api_suffix)  { "route_links" }
  let(:fabricator)  { :route_link }
  let(:model_class) { Vnet::Models::RouteLink }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :uuid => "rl-link",
      :mac_address => "fe:17:9b:9f:e8:33",
    }
    required_params = []
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    accepted_params = { :mac_address => "fe:17:9b:9f:e8:33" }

    include_examples "PUT /:uuid", accepted_params
  end
end
