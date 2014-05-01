# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/translations" do
  before(:each) { use_mock_event_handler }

  let(:api_suffix)  { "translations" }
  let(:fabricator)  { :translation }
  let(:model_class) { Vnet::Models::Translation }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:test_interface) { Fabricate(:interface, uuid: 'if-test') }
    accepted_params = {
      :uuid => "tr-joske",
      :mode => "static_address",
      :interface_uuid => "if-test"
    }
    required_params = [:mode, :interface_uuid]
    uuid_params = [:uuid, :interface_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end
end
