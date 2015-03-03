# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/vlan_translations" do
  before(:each) { use_mock_event_handler }

  let(:api_suffix)  { "vlan_translations" }
  let(:fabricator)  { :vlan_translation }
  let(:model_class) { Vnet::Models::VlanTranslation }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    let!(:translation) do
      Fabricate(:translation,
        uuid: 'tr-test',
        mode: Vnet::Constants::Translation::MODE_VNET_EDGE
      )
    end

    let!(:network) { Fabricate(:network) { uuid "nw-test1" } }

    accepted_params = {
      :uuid => "vt-jantje",
      :translation_uuid => "tr-test",
      :mac_address => "fe:e5:06:64:a6:c3",
      :vlan_id => 1,
      :network_uuid => "nw-test1"
    }

    required_params = [:translation_uuid, :network_uuid]
    uuid_params = [:uuid, :translation_uuid, :network_uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    let!(:translation) do
      Fabricate(:translation,
        uuid: 'tr-test2',
        mode: Vnet::Constants::Translation::MODE_VNET_EDGE
      )
    end

    let!(:network) { Fabricate(:network) { uuid "nw-test2" } }

    accepted_params = {
      :translation_uuid => "tr-test2",
      :mac_address => "fe:e5:06:64:a6:c2",
      :vlan_id => 2,
      :network_uuid => "nw-test2"
    }

    uuid_params = [:translation_uuid, :network_uuid]

    include_examples "PUT /:uuid", accepted_params, uuid_params
  end
end
