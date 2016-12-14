# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/segments" do
  let(:api_suffix)  { "segments" }
  let(:fabricator)  { :segment }
  let(:model_class) { Vnet::Models::Segment }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"
end
