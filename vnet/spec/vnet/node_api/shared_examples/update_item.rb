# -*- coding: utf-8 -*-

# 'update_events': Array of events after deletion.
# 'update_filter': Filter used when calling update on node_api.
# 'model': Item to be updated.
# 'events': Should be 'MockEventHandler.handled_events'.
#
# 'with_lets': The current context is testing with this list of lets. (Usable in lets, e.g. in 'update_events')

# TODO: Add block that allows the caller to include additional tests. (?)

# TODO: Check if there are event params we're not testing for.

# TODO: Add a update thing for deleted items.
# TODO: Add checks to verify that updateing unsupported fields fails.

shared_examples 'update item on node_api' do |name|
  let(:model_class) { Vnet::Models.const_get(name.to_s.camelize) }
  let(:nodeapi_class) { Vnet::NodeApi.const_get(name.to_s.camelize) }

  it 'successfully updated' do
    model

    # Ensure all 'with_lets' are touched in order to create db entries.
    with_lets.each { |let_name| send(let_name) }

    # TODO: Verify result of update.
    nodeapi_class.execute(:update_filter, update_filter, update_params)

    expect(events).to be_event_list_of_size(update_events.size)

    update_events.each_with_index { |event, index|
      expect(events[index]).to be_event_from_model(model, event.first, event.last)
    }
  end
end

shared_examples 'update item on node_api with lets' do |name, let_ids: []|
  [false, true].repeated_permutation(let_ids.size).each { |permutation|
    context "with #{let_context(permutation, let_ids: let_ids)}" do
      let(:with_lets) {
        let_permutation(let_ids, permutation, '_id')
      }
      let_ids.each_with_index { |name, index|
        let("#{name}_id") { permutation[index] ? send(name).id : nil }
      }

      include_examples 'update item on node_api', name
    end
  }
end
