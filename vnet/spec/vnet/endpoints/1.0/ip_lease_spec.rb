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

  describe "DELETE /uuid" do
    describe "event handler" do
      let!(:object) { Fabricate(fabricator) }
      let(:request_params) { object }

      it "handles a single event" do
        delete "ip_leases/#{object.canonical_uuid}"
        expect(last_response).to succeed
        MockEventHandler.handled_events.size.should eq 1
      end
    end
  end

  before(:each) { use_mock_event_handler }

  describe "POST /" do
    #let!(:network) { Fabricate(:network) { uuid "nw-test" } }
    let!(:vif) { Fabricate(:interface) { uuid "vif-test"} }

    accepted_params = {
      :uuid => "il-lease",
      #:network_uuid => "nw-test",
      :vif_uuid => "vif-test",
      :ipv4_address => "192.168.1.10",
      :alloc_type => 1
    }
    #required_params = [:network_uuid, :vif_uuid]
    required_params = [:vif_uuid, :ipv4_address]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params

    describe "event handler" do
      let(:request_params) { accepted_params }

      it "handles a single event" do
        expect(last_response).to succeed
        MockEventHandler.handled_events.size.should eq 1
      end
    end
  end

  #describe "PUT /:uuid" do
  #  #let!(:network) { Fabricate(:network) { uuid "nw-test2" } }
  #  let!(:vif) { Fabricate(:interface) { uuid "vif-test2"} }

  #  accepted_params = {
  #    #:network_uuid => "nw-test2",
  #    :vif_uuid => "vif-test2",
  #    :ipv4_address => "192.168.1.10",
  #    :alloc_type => 2
  #  }

  #  include_examples "PUT /:uuid", accepted_params
  #end
end
