# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/filters" do
  before(:each) { use_mock_event_handler }

  let(:api_suffix)  { "filters" }
  let(:fabricator)  { :filter }
  let(:model_class) { Vnet::Models::Filter }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"
end
