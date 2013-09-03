# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/routes" do
  let(:api_suffix) { "routes" }
  let(:fabricator) { :route }
  let(:model_class) { Vnet::Models::Route }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:vif) { Fabricate(:vif) { uuid "vif-test"}  }
    let!(:route_link) { Fabricate(:route_link) { uuid "rl-test" } }
    accepted_params = {
      :uuid => "r-testrout",
      :vif_uuid => "vif-test",
      :route_link_uuid => "rl-test",
      :ipv4_address => "192.168.10.10",
      :ipv4_prefix => 16,
      :ingress => true,
      :egress => false
    }
    required_params = [:ipv4_address, :route_link_uuid]

    include_examples "POST /", accepted_params, required_params
  end

  describe "PUT /:uuid" do
    let!(:new_vif) { Fabricate(:vif) { uuid 'vif-newvif' } }
    let!(:route_link) { Fabricate(:route_link) { uuid "rl-newroute" } }

    let(:accepted_params) do
      {
        :vif_uuid => "vif-newvif",
        :route_link_uuid => "rl-newroute",
        :ipv4_address => "192.168.3.50",
        :ipv4_prefix => 16,
      }
    end
    uuid_params = [:vif_uuid, :route_link_uuid]

    include_examples "PUT /:uuid", uuid_params
  end

end
