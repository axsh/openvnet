# -*- coding: utf-8 -*-

# 'delete_events': Array of events after deletion.
# 'delete_filter': Filter used when calling delete on node_api.
# 'model': Item to be deleted.
# 'events': Should be 'MockEventHandler.handled_events'.
#
# 'with_lets': The current context is testing with this list of lets. (Usable in lets, e.g. in 'delete_events')

# TODO: Add block that allows the caller to include additional tests. (?)

# TODO: Check if there are event params we're not testing for.

shared_examples 'delete item on node_api' do |name|
  let(:model_class) { Vnet::Models.const_get(name.to_s.camelize) }
  let(:nodeapi_class) { Vnet::NodeApi.const_get(name.to_s.camelize) }

  let(:all_deletions) {
    extra_deletions.inject([model_class]) { |deletions, extra_name|
      deletions << Vnet::Models.const_get(extra_name.to_s.camelize)
    }
  }

  it 'successfully deleted' do
    model

    # Ensure all 'with_lets' are touched in order to create db entries.
    with_lets.each { |let_name| send(let_name) }

    # TODO: Verify result of destroy.
    pre_counts = all_deletions.map { |m_class| m_class.count }
    nodeapi_class.execute(:destroy, delete_filter)
    post_counts = all_deletions.map { |m_class| m_class.count }

    expect(post_counts).to eq(pre_counts.map { |c| c - 1 })
    expect(events).to be_event_list_of_size(delete_events.size)

    delete_events.each_with_index { |event, index|
      expect(events[index]).to be_event_from_model(model, event.first, event.last)
    }
  end
end


shared_examples 'delete item on node_api with lets' do |name, let_ids: []|
  [false, true].repeated_permutation(let_ids.size).each { |permutation|
    context "with #{let_context(permutation, let_ids: let_ids)}" do
      let(:with_lets) {
        let_permutation(let_ids, permutation, '_id')
      }
      let_ids.each_with_index { |name, index|
        let("#{name}_id") { permutation[index] ? send(name).id : nil }
      }

      include_examples 'delete item on node_api', name
    end
  }
end
