# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/datapaths" do
  let(:api_suffix)  { "datapaths" }
  let(:fabricator)  { :datapath }
  let(:model_class) { Vnet::Models::Datapath }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:dc_segment) { Fabricate(:dc_segment) { uuid "ds-segment" } }
    accepted_params = {
      :uuid => "dp-test",
      :display_name => "our test datapath",
      :ipv4_address => "192.168.50.100",
      :is_connected => false,
      :dpid => "0x0000aaaaaaaaaaaa",
      :node_id => "vna45",
      :dc_segment_uuid => "ds-segment"
    }

    required_params = [:display_name, :dpid, :node_id]
    uuid_params = [:uuid, :dc_segment_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    let!(:new_dc_segment) { Fabricate(:dc_segment) { uuid "ds-newseg" } }
    accepted_params = {
      :display_name => "we changed this name",
      :ipv4_address => "192.168.2.50",
      :dpid => "0x0000abcdefabcdef",
      :dc_segment_uuid => "ds-newseg",
      :node_id => 'vna45'
    }
    uuid_params = [:dc_segment_uuid]

    include_examples "PUT /:uuid", accepted_params, uuid_params
  end

  describe "POST /:uuid/networks/:network_uuid" do
    let!(:related_object) { Fabricate(:network) }
    let!(:base_object) { Fabricate(fabricator) }

    before(:each) do
      post api_relation_suffix, request_params
    end

    let(:request_params) { {:broadcast_mac_addr => "02:00:00:cc:00:02"} }

    context "with a nonexistant uuid for the base object" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{model_class.uuid_prefix}-notfound/networks/#{related_object.canonical_uuid}"
      }

      it "should return a 404 error (UnknownUUIDResource)" do
        last_response.should fail.with_code(404).with_error("UnknownUUIDResource",
          "#{model_class.uuid_prefix}-notfound")
      end
    end

    context "with a nonexistant uuid for the relation" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/networks/#{related_object.uuid_prefix}-notfound"
      }

      it "should return a 404 error (UnknownUUIDResource)" do
        last_response.should fail.with_code(404).with_error("UnknownUUIDResource",
          "#{related_object.uuid_prefix}-notfound")
      end
    end

    context "with faulty uuid syntax for the base object" do
      let(:api_relation_suffix) {
        "#{api_suffix}/this_is_not_an_uuid/networks/#{related_object.canonical_uuid}"
      }

      it_should_return_error(400, "InvalidUUID", "this_is_not_an_uuid")
    end

    context "with faulty uuid syntax for the related object" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/networks/this_is_not_an_uuid"
      }

      it_should_return_error(400, "InvalidUUID", "this_is_not_an_uuid")
    end

    context "with a network_uuid that isn't added to this datapath yet" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/networks/#{related_object.canonical_uuid}"
      }

      it "should succeed" do
        last_response.should succeed
      end
    end
  end

end
