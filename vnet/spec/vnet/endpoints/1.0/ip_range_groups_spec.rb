# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/ip_range_groups" do
  let(:api_suffix)  { "ip_range_groups" }
  let(:fabricator)  { :ip_range_group }
  let(:model_class) { Vnet::Models::IpRangeGroup }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :allocation_type => "incremental"
    }
    required_params = [ ]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "One to many relation calls for ip_ranges" do
    pending "TODO, this does not work because url route is different from table name and this table does not have a uuid"
#    let(:relation_fabricator) { :ip_range }

#    include_examples "one_to_many_relation", "ranges", {
#                       :begin_ipv4_address => "0.0.0.40",
#                       :end_ipv4_address => "0.0.0.50"
#    }
  end
end
