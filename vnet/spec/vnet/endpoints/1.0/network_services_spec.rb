# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe '/network_services' do
  before(:each) { use_mock_event_handler }
  let(:api_suffix)  { 'network_services' }
  let(:fabricator)  { :network_service_dhcp }
  let(:model_class) { Vnet::Models::NetworkService }

  include_examples 'GET /'
  include_examples 'GET /:uuid'
  include_examples 'DELETE /:uuid'

  describe 'POST /' do
    let!(:interface) { Fabricate(:interface) { uuid 'if-test'}  }
    accepted_params = {
      :uuid => 'ns-test',
      :display_name => 'display name',
      :interface_uuid => 'if-test',
      :mode => 'dhcp',
      :incoming_port => 40,
      :outgoing_port => 100
    }
    required_params = [:mode]
    uuid_params = [:uuid, :interface_uuid]

    include_examples 'POST /', accepted_params, required_params, uuid_params
  end

  describe 'PUT /:uuid' do
    let!(:new_interface) { Fabricate(:interface) { uuid 'if-other'}  }

    accepted_params = {
      :display_name => 'new display name',
    }
    uuid_params = []

    include_examples 'PUT /:uuid', accepted_params, uuid_params
  end

end
