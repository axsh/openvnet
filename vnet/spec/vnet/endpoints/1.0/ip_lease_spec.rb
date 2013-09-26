# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/ip_leases" do
  let(:api_suffix)  { "ip_leases" }
  let(:fabricator)  { :ip_lease }
  let(:model_class) { Vnet::Models::IpLease }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:network) { Fabricate(:network) { uuid "nw-test" } }
    let!(:interface) { Fabricate(:interface) { uuid "if-test"} }
    let!(:ip_address) { Fabricate(:ip_address) { uuid "ia-test" } }

    accepted_params = {
      :uuid => "il-lease",
      :network_uuid => "nw-test",
      :interface_uuid => "if-test",
      :ip_address_uuid => "ia-test",
    }
    required_params = [:network_uuid, :interface_uuid, :ip_address_uuid]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    let!(:network) { Fabricate(:network) { uuid "nw-test2" } }
    let!(:interface) { Fabricate(:interface) { uuid "if-test2"} }
    let!(:ip_address) { Fabricate(:ip_address) { uuid "ia-test2" } }

    accepted_params = {
      :network_uuid => "nw-test2",
      :interface_uuid => "if-test2",
      :ip_address_uuid => "ia-test2",
    }

    include_examples "PUT /:uuid", accepted_params
  end

end
