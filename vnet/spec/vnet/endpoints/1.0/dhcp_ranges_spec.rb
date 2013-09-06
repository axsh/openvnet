# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/dhcp_ranges" do
  let(:api_suffix) { "dhcp_ranges" }
  let(:fabricator) { :dhcp_range }
  let(:model_class) { Vnet::Models::DhcpRange }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:network) { Fabricate(:network) { uuid "nw-testnet" } }
    accepted_params = {
      :uuid => "dr-testrang",
      :network_uuid => "nw-testnet",
      :range_begin => "192.168.1.2",
      :range_end => "192.168.1.100"
    }
    required_params = [:network_uuid, :range_begin, :range_end]
    uuid_params = [:uuid, :network_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    let!(:network) { Fabricate(:network) { uuid "nw-test" } }
    accepted_params = {
      :network_uuid => "nw-test",
      :range_begin => "192.168.1.200",
      :range_end => "192.168.1.240"
    }
    uuid_params = [:network_uuid]

    include_examples "PUT /:uuid", accepted_params, uuid_params
  end

end
