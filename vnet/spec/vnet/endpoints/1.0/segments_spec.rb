# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet/endpoints/1.0/vnet_api'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/segments" do
  before(:each) { use_mock_event_handler }

  let(:api_suffix)  { "segments" }
  let(:fabricator)  { :segment }
  let(:model_class) { Vnet::Models::Segment }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    expected_response = {
      :uuid => "seg-test",
      :mode => "virtual"
    }
    accepted_params = expected_response
    required_params = [:mode]
    uuid_params = []

    include_examples "POST /", accepted_params, required_params, uuid_params, expected_response

    context "With a wrong value for mode" do
      let(:request_params) { { mode: "klein soldaatje, groot soldaatje" } }

      it_should_return_error(400, "ArgumentError")
    end
  end

  describe "PUT /:uuid" do
    accepted_params = {
      :mode => "physical"
    }

    include_examples "PUT /:uuid", accepted_params
  end
end
