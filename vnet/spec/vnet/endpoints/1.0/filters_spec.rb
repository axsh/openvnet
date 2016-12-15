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

  describe "POST /" do
    let!(:interface) { Fabricate(:interface) { uuid "if-filtest" } }

    expected_response = {
      :uuid => "fil-test",
      :interface_uuid => "if-filtest",
      :egress_passthrough => true,
      :ingress_passthrough => true,
      :mode => "static"
    }
    accepted_params = expected_response
    required_params = [:interface_uuid, :mode]
    uuid_params = [:interface_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params, expected_response

    context "With a wrong value for mode" do
      let(:request_params) { accepted_params.merge({ mode: "a squirrel" }) }

      it_should_return_error(400, "ArgumentError")
    end
  end

  describe "PUT /:uuid" do
    let!(:interface) { Fabricate(:interface) { uuid "if-test" } }

    accepted_params = {
      :egress_passthrough => true,
      :ingress_passthrough => true,
    }

    include_examples "PUT /:uuid", accepted_params
  end

  describe "/:uuid/static" do
    let!(:filter) { Fabricate(:filter, mode: "static") }

    let(:api_suffix) { "filters/#{filter.canonical_uuid}/static" }
    let(:fabricator) { :filter_static}
    let(:model_class) { Vnet::Models::FilterStatic }

    accepted_params = {
      ipv4_address: "192.168.100.150",
      port_number: 24056,
      protocol: "tcp",
      passthrough: true
    }
    required_params = [:ipv4_address, :protocol, :port_number, :passthrough]
    uuid_params = []

    describe "POST" do
      include_examples "POST /", accepted_params, required_params, uuid_params
    end
  end
end
