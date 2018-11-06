# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/mac_leases" do
  before(:each) { use_mock_event_handler }
  let(:api_suffix)  { "mac_leases" }
  let(:fabricator)  { :mac_lease }
  let(:model_class) { Vnet::Models::MacLease }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  before do
    Fabricate(:interface)
  end

  describe "POST /" do
    let!(:interface) { Fabricate(:interface) { uuid "if-test" } }
    let!(:segment) { Fabricate(:segment) { uuid "seg-test" } }

    accepted_params = {
      uuid: "ml-test",
      interface_uuid: "if-test",
      mac_address: "00:21:cc:da:e9:cc",
      segment_uuid: "seg-test",
    }
    required_params = [:mac_address]
    uuid_params = [:uuid, :interface_uuid, :segment_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    let!(:interface) { Fabricate(:interface) { uuid "if-test2" } }

    accepted_params = {
      :interface_uuid => "if-test2",
    }

    include_examples "PUT /:uuid", accepted_params
  end
end
