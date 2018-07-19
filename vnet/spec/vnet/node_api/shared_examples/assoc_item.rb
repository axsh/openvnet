# -*- coding: utf-8 -*-

shared_examples 'assoc item on node_api' do |parent_assoc_name, extra_model_params = {}|

  before(:each) { use_mock_event_handler }

  let(:events) { MockEventHandler.handled_events }

  let(:assoc_id_sym) { "#{assoc_name}_id".to_sym }
  let(:parent_id_sym) { "#{parent_name}_id".to_sym }
  let(:parent_assoc_model) { Fabricate(parent_assoc_name, model_params) }

  let(:model_params) {
    { assoc_id_sym => assoc_model.id,
      parent_id_sym => parent_model.id
    }.merge(extra_model_params)
  }

  let(:added_event) {
    [ added_event_name, {
        :id => parent_model.id,
        assoc_id_sym => assoc_model.id
      }]
  }
  let(:removed_event) {
    [ removed_event_name, {
        :id => parent_model.id,
        assoc_id_sym => assoc_model.id
      }]
  }

  describe 'create' do
    let(:create_result) { model_params }
    let(:query_result) { create_result }
    let(:create_events) { [added_event] }
    let(:extra_creations) { [] }

    include_examples 'create item on node_api with lets', parent_assoc_name, let_ids: []
  end

  describe 'update' do
    let(:model) { parent_assoc_model }

    let(:update_filter) { { id: model.id } }
    let(:update_events) { [] }
    let(:update_params) { {} }

    include_examples 'update item on node_api with lets', parent_assoc_name, let_ids: []
  end

  describe 'destroy' do
    let(:model) { parent_assoc_model }

    let(:delete_filter) { { id: model.id } }
    let(:delete_events) { [removed_event] }
    let(:extra_deletions) { [] }

    include_examples 'delete item on node_api with lets', parent_assoc_name, let_ids: []
  end

end
