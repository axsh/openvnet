# -*- coding: utf-8 -*-

require 'spec_helper'

Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }

describe Vnet::NodeApi::MacLease do
  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }

  # let(:interface) { Fabricate(:interface) }
  # let(:segment) { Fabricate(:segment) }

  # let(:random_mac_address) { random_mac_i }

  let(:model_params) {
    { mode: 'simple'
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
