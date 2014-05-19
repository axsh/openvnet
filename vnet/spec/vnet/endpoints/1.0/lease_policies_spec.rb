# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/lease_policies" do
  before(:each) { use_mock_event_handler }
  let(:api_suffix)  { "lease_policies" }
  let(:fabricator)  { :lease_policy }
  let(:model_class) { Vnet::Models::LeasePolicy }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :uuid => "lp-test",
      :mode => "simple",
      # making the timing not "immediate", because allocate_ip() would
      # start requiring a lot more database setup
      :timing => "dhcp",
      # but timing is not a required parameter, and its default is "immediate"
      # so still have to do the database setup :-(
      :lease_time => 7200,
    }
    required_params = [ ]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    accepted_params = {
      :mode => "simple",
      :timing => "immediate"
    }

    include_examples "PUT /:uuid", accepted_params
  end

  describe "Many to many relation calls for networks" do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :network }

    let!(:ip_range_group) { Fabricate(:ip_range_group) { uuid "iprg-test" } }

    include_examples "many_to_many_relation", "networks", {
                       :ip_range_group_uuid => 'iprg-test'
                     }
  end

  describe "Many to many relation calls for interfaces" do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :interface_w_mac_lease }

    let!(:network) { Fabricate(:network) {
                       uuid "nw-test"
                       ipv4_network 167772416
                       ipv4_prefix 24
                     } }
    let!(:ip_range_group) { Fabricate(:ip_range_group) {
                        uuid "iprg-test"
                        allocation_type "incremental"
                      } }
    let!(:ip_range) {
      Fabricate(:ip_range,
                ip_range_group_id: ip_range_group.id,
                begin_ipv4_address: 167772417,
                end_ipv4_address: 167772426 )
    }
    let!(:lease_policy_base_network) {
      Fabricate(:lease_policy_base_network,
        lease_policy_id: base_object.id,
        network_id: network.id,
        ip_range_group_id: ip_range_group.id )
    }

    include_examples "many_to_many_relation", "interfaces", {}
  end
end
