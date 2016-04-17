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

  describe "PUT /:uuid" do
    let!(:test_interface) { Fabricate(:interface, uuid: 'if-test2') }

    accepted_params = {
      :interface_uuid => "if-test2"
    }

    include_examples "PUT /:uuid", accepted_params
  end

  describe "/:uuid/static_address" do
    let!(:translation) { Fabricate(:translation, mode: "static_address") }

    let(:api_suffix) { "translations/#{translation.canonical_uuid}/static_address" }
    let(:fabricator) { :translation_static_address }
    let(:model_class) { Vnet::Models::TranslationStaticAddress }

    shared_examples_for "static address mode only" do
      context "with a translation that isn't in static_address mode" do
        let!(:translation) { Fabricate(:translation, mode: 'vnet_edge') }
        let(:request_params) do
          {ingress_ipv4_address: "192.168.2.10",
           egress_ipv4_address: "192.168.2.30"}
        end

        it_should_return_error(400, 'ArgumentError')
      end
    end

    accepted_params = {
      ingress_ipv4_address: "192.168.2.10",
      egress_ipv4_address: "192.168.2.30",
      ingress_port_number: 1,
      egress_port_number: 3
    }

    required_params = [:ingress_ipv4_address, :egress_ipv4_address]

    describe "POST" do
      let!(:route_link) { Fabricate(:route_link, uuid: "rl-jefke") }

      p_accepted_params = accepted_params.merge({
        route_link_uuid: "rl-jefke",
        ingress_network_uuid: "nw-global",
        egress_network_uuid: "nw-vnet"
      })

      uuid_params = [:route_link_uuid]

      include_examples "POST /", p_accepted_params, required_params, uuid_params

      include_examples "static address mode only"
    end

    describe "DELETE" do
      let(:db_fields) do
        accepted_params.merge({translation_id: translation.id}).tap { |h|
          h[:ingress_ipv4_address] = 3232236042
          h[:egress_ipv4_address] = 3232236062
        }
      end

      let(:translation_static_address) do
        Fabricate(:translation_static_address, db_fields)
      end

      before(:each) do
        translation_static_address
        delete api_suffix, request_params
      end

      include_examples "required parameters", accepted_params, required_params

      context "with parameters describing a non existing static address translation" do
        let(:request_params) { accepted_params.merge({ingress_port_number: 2}) }

        it_should_return_error(404, 'UnknownResource')
      end

      context "with parameters describing an existing static address translation" do
        let(:request_params) { accepted_params }

        it "should delete one database entry" do
          expect(last_response).to succeed
          expect(model_class.find(db_fields)).to eq(nil)
        end
      end
    end
  end
end
