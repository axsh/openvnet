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

  describe "/:uuid/static_address" do
    let!(:translation) { Fabricate(:translation, mode: "static_address") }

    let(:api_suffix) { "translations/#{translation.canonical_uuid}/static_address" }
    let(:fabricator) { :translation_static_address }
    let(:model_class) { Vnet::Models::TranslationStaticAddress }

    describe "POST" do
      let!(:route_link) { Fabricate(:route_link, uuid: "rl-jefke") }

      accepted_params = {
        ingress_ipv4_address: "192.168.2.10",
        egress_ipv4_address: "192.168.2.30",
        ingress_port_number: 1,
        egress_port_number: 3,
        route_link_uuid: "rl-jefke"
      }

      required_params = [:ingress_ipv4_address, :egress_ipv4_address]
      uuid_params = [:route_link_uuid]

      include_examples "POST /", accepted_params, required_params, uuid_params
    end
  end
end
