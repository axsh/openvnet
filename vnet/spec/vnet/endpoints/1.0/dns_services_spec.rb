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
    let!(:network_service) { Fabricate(:network_service, uuid: "ns-test", type: "dns")  }
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

  describe "POST /:uuid/dns_records" do
    before(:each) do
      post api_suffix_with_uuid, request_params
    end

    # let(:accepted_params) do
    accepted_params = {
        uuid: "dnsr-new",
        name: "test-server",
        ipv4_address: "192.168.1.10",
      }
    # end
    let(:request_params) { accepted_params }

    context "with a nonexistant uuid" do
      let(:api_suffix_with_uuid) { "#{api_suffix}/dnss-notfound/dns_records" }

      it "should return a 404 error (UnknownUUIDResource)" do
        expect(last_response).to fail.with_code(404).with_error("UnknownUUIDResource",
          /dnss-notfound$/)
      end
    end

    context "with a uuid parameter with a faulty syntax" do
      let(:api_suffix_with_uuid) { "#{api_suffix}/this_aint_no_uuid/dns_records" }

      it_should_return_error(400, "InvalidUUID", /this_aint_no_uuid$/)
    end

    context "with an existing uuid" do
      let!(:dns_service) { Fabricate(:dns_service) }
      let(:api_suffix_with_uuid) { "#{api_suffix}/#{dns_service.canonical_uuid}/dns_records" }

      context "with all accepted parameters" do
        it "should create a new dns record" do
          expect(last_response).to succeed
          expect(JSON.parse(last_response.body)["dns_records"].size).to eq 1
        end
      end

      context "with a dns record uuid that already exists" do
        # A second call to bring forth the error
        before(:each) { post api_suffix_with_uuid, request_params }

        it_should_return_error(400, "DuplicateUUID", /dnsr-new$/)
      end

      include_examples "required parameters", accepted_params,
        [:name, :ipv4_address]

    end
  end

end
