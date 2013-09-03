# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/network_services" do
  let(:api_suffix)  { "network_services" }
  let(:fabricator)  { :network_service }
  let(:model_class) { Vnet::Models::NetworkService }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:vif) { Fabricate(:vif) { uuid "vif-test"}  }
    accepted_params = {
      :uuid => "ns-test",
      :vif_uuid => "vif-test",
      :display_name => "our test network service",
      :incoming_port => 40,
      :outgoing_port => 100
    }
    required_params = [:display_name]

    include_examples "POST /", accepted_params, required_params
  end

  describe "PUT /:uuid" do
    let!(:new_vif) { Fabricate(:vif) { uuid "vif-other"}  }
    let(:accepted_params) do
      {
        :vif_uuid => "vif-other",
        :display_name => "our new and improved test network service",
        :incoming_port => 40,
        :outgoing_port => 100
      }
    end
    uuid_params = [:vif_uuid]

    include_examples "PUT /:uuid", uuid_params
  end

end
