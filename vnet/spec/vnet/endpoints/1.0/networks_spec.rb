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

  describe 'DELETE /:uuid' do
    context 'With ip leases in the database' do
      let(:test_network) { Fabricate(:network) }

      before(:each) {
        3.times { Fabricate(:ip_lease, network_id: test_network.id) }

        delete "#{api_suffix}/#{test_network.canonical_uuid}"
      }

      it "deletes all the ip leases along with the network" do
        expect(last_response).to succeed

        expect(model_class[test_network.canonical_uuid]).to eq(nil)
        expect(model_class.with_deleted.where(uuid: test_network.uuid)).not_to eq(nil)

        expect(Vnet::Models::IpLease.count).to eq(0)
        expect(Vnet::Models::IpLease.with_deleted.count).to eq(3)

        expect(Vnet::Models::IpAddress.where(network: test_network).count).to eq(0)
        expect(Vnet::Models::IpAddress.with_deleted.where(network: test_network).count).to eq(3)
      end
    end
  end

  describe 'POST /' do
    let!(:topology) { Fabricate(:topology) { uuid 'topo-test' }  }

    accepted_params = {
      uuid: 'nw-test',
      display_name: 'our test network',
      ipv4_network: '192.168.2.0',
      ipv4_prefix: 24,
      domain_name: 'vdc.test.domain',
      mode: 'virtual',
      topology_uuid: 'topo-test'
    }
    expected_response = accepted_params.dup.tap { |map|
      map.delete(:topology_uuid)
    }

    required_params = [:ipv4_network]
    uuid_params = [:uuid]

    include_examples 'POST /', accepted_params, required_params, uuid_params, expected_response, Proc.new { |model, last_response|
      other_model = Vnet::Models::Topology[accepted_params[:topology_uuid]]
      other_model && Vnet::Models::TopologyNetwork[network_id: model.id, topology_id: other_model.id]
    }
  end

  describe 'PUT /:uuid' do
    accepted_params = {
      display_name: 'our new name for the test network',
      domain_name: 'new.vdc.test.domain',
    }

    include_examples 'PUT /:uuid', accepted_params
  end
end
