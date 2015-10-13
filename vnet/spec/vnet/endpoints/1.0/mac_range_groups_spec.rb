# -*- coding: utf-8 -*-

require 'spec_helper'
require 'vnet'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/mac_range_groups" do
  let(:api_suffix)  { "mac_range_groups" }
  let(:fabricator)  { :mac_range_group }
  let(:model_class) { Vnet::Models::MacRangeGroup }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :allocation_type => "random"
    }
    required_params = [ ]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    accepted_params = {
      :allocation_type => "random"
    }

    include_examples "PUT /:uuid", accepted_params
  end

  describe "One to many relation calls for mac_ranges" do
    let(:relation_fabricator) { :mac_range }
    let(:relation_uuid) { "mr-new" }

    include_examples "one_to_many_relation",
      "mac_ranges", {
      :uuid => "macr-new",
      :begin_mac_address => "08:00:27:aa:00:00",
      :end_mac_address => "08:00:27:cc:ff:ff"
    }
  end

end
