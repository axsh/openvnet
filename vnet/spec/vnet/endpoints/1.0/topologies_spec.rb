# -*- coding: utf-8 -*-

require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe '/topologies' do
  before(:each) { use_mock_event_handler }
  let(:api_suffix)  { 'topologies' }
  let(:fabricator)  { :topology }
  let(:model_class) { Vnet::Models::Topology }

  include_examples 'GET /'
  include_examples 'GET /:uuid'
  include_examples 'DELETE /:uuid'

  describe 'POST /' do
    accepted_params = {
      :uuid => 'topo-test',
      :mode => 'simple_underlay'
    }

    required_params = [:mode]
    uuid_params = [:uuid]

    include_examples 'POST /', accepted_params, required_params, uuid_params
  end

  describe 'PUT /:uuid' do
    accepted_params = {
    }
    uuid_params = []

    include_examples 'PUT /:uuid', accepted_params, uuid_params
  end

  describe 'Many to many relation calls for underlays' do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :topology }
    let(:base_name) { :overlay }
    let(:relation_name) { :underlay }
    let(:join_table_fabricator) { :topology_underlay }

    include_examples 'many_to_many_relation', 'underlays', {
    }
  end

  describe 'Many to many relation calls for datapaths' do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :datapath }

    let!(:interface) { Fabricate(:interface_w_ip_lease) { uuid 'if-test' } }

    include_examples 'many_to_many_relation', 'datapaths', {
      :interface_uuid => 'if-test'
    }
  end

  describe 'Many to many relation calls for networks' do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :network }

    include_examples 'many_to_many_relation', 'networks', {
    }
  end

  describe 'Many to many relation calls for segments' do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :segment }

    include_examples 'many_to_many_relation', 'segments', {
    }
  end

  describe 'Many to many relation calls for route_links' do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { :route_link }

    include_examples 'many_to_many_relation', 'route_links', {
    }
  end

end
