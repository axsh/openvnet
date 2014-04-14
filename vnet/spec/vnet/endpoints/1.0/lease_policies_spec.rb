# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/lease_policies" do
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
      :timing => "immediate"
    }
    required_params = [ ]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "Many to many relation calls for networks" do
    let(:relation_fabricator) { :network }

    let!(:ip_range) { Fabricate(:ip_range) { uuid "ipr-test" } }

    include_examples "many_to_many_relation", "networks", {
                       :ip_range_uuid => 'ipr-test'
                     }
  end
end
