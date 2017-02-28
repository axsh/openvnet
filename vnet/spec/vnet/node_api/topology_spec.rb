# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::Topology do
  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }

  let(:model_params) {
    { mode: 'simple_underlay'
    }
  }

  let(:topology_created_event) {
    [ Vnet::Event::TOPOLOGY_CREATED_ITEM, {
        id: :model__id,
        uuid: :model__uuid,
        mode: model_params[:mode]
      }]
  }
  let(:topology_deleted_event) {
    [ Vnet::Event::TOPOLOGY_DELETED_ITEM, {
        id: :model__id
      }]
  }

  describe 'create' do
    let(:create_result) { model_params }
    let(:query_result) { create_result }

    let(:create_events) {
      [topology_created_event]
    }
    let(:extra_creations) { [] }

    include_examples 'create item on node_api with lets', :topology, let_ids: []
  end

  describe 'update' do
    let(:model) { Fabricate(:topology, model_params) }
    let(:update_filter) { model.canonical_uuid }
    let(:update_events) {
      []
    }
    let(:update_params) {
      {}
    }

    include_examples 'update item on node_api with lets', :topology, let_ids: []
  end

  describe 'destroy' do
    let(:model) { Fabricate(:topology, model_params) }
    let(:delete_filter) { model.canonical_uuid }

    let(:delete_events) {
      [topology_deleted_event]
    }
    let(:extra_deletions) { [] }

    include_examples 'delete item on node_api with lets', :topology, let_ids: []
  end

end

describe Vnet::NodeApi::TopologyNetwork do
  let(:assoc_name) { :network }
  let(:parent_name) { :topology }

  let(:assoc_model) { Fabricate(:network) }
  let(:parent_model) { Fabricate(:topology, mode: 'simple_underlay') }

  let(:added_event_name) { Vnet::Event::TOPOLOGY_ADDED_NETWORK }
  let(:removed_event_name) { Vnet::Event::TOPOLOGY_REMOVED_NETWORK }

  include_examples 'assoc item on node_api', :topology_network
end

describe Vnet::NodeApi::TopologySegment do
  let(:assoc_name) { :segment }
  let(:parent_name) { :topology }

  let(:assoc_model) { Fabricate(:segment) }
  let(:parent_model) { Fabricate(:topology, mode: 'simple_underlay') }

  let(:added_event_name) { Vnet::Event::TOPOLOGY_ADDED_SEGMENT }
  let(:removed_event_name) { Vnet::Event::TOPOLOGY_REMOVED_SEGMENT }

  include_examples 'assoc item on node_api', :topology_segment
end

describe Vnet::NodeApi::TopologyRouteLink do
  let(:assoc_name) { :route_link }
  let(:parent_name) { :topology }

  let(:assoc_model) { Fabricate(:route_link) }
  let(:parent_model) { Fabricate(:topology, mode: 'simple_underlay') }

  let(:added_event_name) { Vnet::Event::TOPOLOGY_ADDED_ROUTE_LINK }
  let(:removed_event_name) { Vnet::Event::TOPOLOGY_REMOVED_ROUTE_LINK }

  include_examples 'assoc item on node_api', :topology_route_link
end
