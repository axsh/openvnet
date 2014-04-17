# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/ip_ranges" do
  let(:api_suffix)  { "ip_ranges" }
  let(:fabricator)  { :ip_range }
  let(:model_class) { Vnet::Models::IpRange }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :allocation_type => "incremental"
    }
    required_params = [ ]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end
end
