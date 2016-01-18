# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/dns_services" do
  before(:each) { use_mock_event_handler }
  let(:api_suffix)  { "dns_services" }
  let(:fabricator)  { :dns_service }
  let(:model_class) { Vnet::Models::DnsService }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:network_service) { Fabricate(:network_service, uuid: "ns-test", mode: "dns")  }
    accepted_params = {
      uuid: "dnss-test",
      network_service_uuid: "ns-test",
      public_dns: "8.8.8.8,8.8.4.4",
    }
    required_params = [:network_service_uuid]
    uuid_params = [:uuid, :network_service_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    accepted_params = {
      public_dns: "1.2.3.4",
    }

    include_examples "PUT /:uuid", accepted_params
  end

  describe "One to many relation calls for dns_records" do
    let(:relation_fabricator) { :dns_record }
    let(:relation_uuid) { "dnsr-new" }

    include_examples "one_to_many_relation", "dns_records", {
      uuid: "dnsr-new",
      name: "test-server",
      ipv4_address: "192.168.1.10",
    }
  end
end
