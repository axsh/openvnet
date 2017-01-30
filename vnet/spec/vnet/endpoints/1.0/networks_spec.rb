# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe '/networks' do
  before(:each) { use_mock_event_handler }

  let(:api_suffix)  { 'networks' }
  let(:fabricator)  { :network }
  let(:model_class) { Vnet::Models::Network }

  include_examples 'GET /'
  include_examples 'GET /:uuid'
  include_examples 'DELETE /:uuid'

  describe 'POST /' do
    let!(:topology) { Fabricate(:topology) { uuid 'topo-test' }  }

    accepted_params = {
      uuid: 'nw-test',
      display_name: 'our test network',
      ipv4_network: '192.168.2.0',
      ipv4_prefix: 24,
      domain_name: 'vdc.test.domain',
      network_mode: 'virtual',
      topology_uuid: 'topo-test'
    }
    expected_response = accepted_params.dup.tap { |map|
      map.delete(:topology_uuid)
    }
    
    required_params = [:display_name, :ipv4_network]
    uuid_params = [:uuid]

    include_examples 'POST /', accepted_params, required_params, uuid_params, expected_response
  end

  describe 'PUT /:uuid' do
    accepted_params = {
      display_name: 'our new name for the test network',
      domain_name: 'new.vdc.test.domain',
    }

    include_examples 'PUT /:uuid', accepted_params
  end
end
