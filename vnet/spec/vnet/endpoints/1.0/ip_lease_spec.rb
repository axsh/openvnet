# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/ip_leases" do
  before(:each) { use_mock_event_handler }

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

  describe "POST /" do

    let!(:network) { Fabricate(:network) { uuid "nw-test" } }
    let!(:interface) { Fabricate(:interface) { uuid "if-test" } }

    accepted_params = {
      :uuid => "il-lease",
      :network_uuid => "nw-test",
      :interface_uuid => "if-test",
      :ipv4_address => "192.168.1.10",
    }
    required_params = [:interface_uuid, :network_uuid, :ipv4_address]
    uuid_params = [:uuid, :interface_uuid, :network_uuid]

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
  #  let!(:network) { Fabricate(:network) { uuid "nw-test2" } }
  #  let!(:interface) { Fabricate(:interface) { uuid "if-test2" } }

  #  accepted_params = {
  #    :network_uuid => "nw-test2",
  #    :interface_uuid => "if-test2",
  #    :ipv4_address => "192.168.1.10",
  #  }

  #  include_examples "PUT /:uuid", accepted_params

  #  describe "event handler" do
  #    let(:request_params) { accepted_params }

  #    it "handles a single event" do
  #      expect(last_response).to succeed
  #      MockEventHandler.handled_events.size.should eq 2
  #    end
  #  end
  #end
end
