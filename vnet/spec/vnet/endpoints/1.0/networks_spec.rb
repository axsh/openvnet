# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/networks" do
  let(:api_suffix)  { "networks" }
  let(:fabricator)  { :network }
  let(:model_class) { Vnet::Models::Network }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :uuid => "nw-test",
      :display_name => "our test network",
      :ipv4_network => "192.168.2.0",
      :ipv4_prefix => 24,
      :domain_name => "vdc.test.domain",
      :network_mode => "virtual",
      :editable => false
    }
    required_params = [:display_name, :ipv4_network]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    accepted_params = {
      :display_name => "our new name for the test network",
      :ipv4_network => "10.0.0.2",
      :ipv4_prefix => 8,
      :domain_name => "new.vdc.test.domain",
      :network_mode => "physical",
      :editable => true
    }

    include_examples "PUT /:uuid", accepted_params
  end

  describe "POST /:network_uuid/dhcp_ranges" do
    before(:each) do
      post api_suffix_with_uuid, request_params
    end

    # let(:accepted_params) do
    accepted_params = {
        :uuid => "dr-newrange",
        :range_begin => "192.168.2.2",
        :range_end => "192.168.2.100"
      }
    # end
    let(:request_params) { accepted_params }

    context "with a nonexistant network_uuid" do
      let(:api_suffix_with_uuid) { "#{api_suffix}/nw-notfound/dhcp_ranges" }

      it "should return a 404 error (UnknownUUIDResource)" do
        last_response.should fail.with_code(404).with_error("UnknownUUIDResource",
          /nw-notfound$/)
      end
    end

    context "with a uuid parameter with a faulty syntax" do
      let(:api_suffix_with_uuid) { "#{api_suffix}/this_aint_no_uuid/dhcp_ranges" }

      it_should_return_error(400, "InvalidUUID", /this_aint_no_uuid$/)
    end

    context "with an existing network_uuid" do
      let!(:network) { Fabricate(:network) }
      let(:api_suffix_with_uuid) { "#{api_suffix}/#{network.canonical_uuid}/dhcp_ranges" }

      context "with all accepted parameters" do
        it "should create a new dhcp range" do
          last_response.should succeed
          JSON.parse(last_response.body)["dhcp_ranges"].size.should eq 1
        end
      end

      context "with a dhcp range uuid that already exists" do
        # A second call to bring forth the error
        before(:each) { post api_suffix_with_uuid, request_params }

        it_should_return_error(400, "DuplicateUUID", /dr-newrange$/)
      end

      include_examples "required parameters", accepted_params,
        [:range_begin, :range_end]

    end
  end

end
