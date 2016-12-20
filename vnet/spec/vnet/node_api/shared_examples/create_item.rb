# -*- coding: utf-8 -*-

# 'model_params': Parameters used when calling create on nodeapi.
# 'create_events': Array of events after deletion.
# 'create_result': Expected result from call to nodeapi create. (Optional)
# 'query_result': Expected result from call to nodeapi query. (Optional)
# 'events': Should be 'MockEventHandler.handled_events'.
#
# 'with_lets': The current context is testing with this list of lets. (Usable in let blocks, e.g. in 'create_events')

# TODO: Add block that allows the caller to include additional tests. (?)

# TODO: Check if there are event params we're not testing for.

shared_examples 'create item on node_api' do |name|
  let(:model) { nodeapi_class.execute(:create, model_params) }
  let(:model_class) { Vnet::Models.const_get(name.to_s.camelize) }
  let(:nodeapi_class) { Vnet::NodeApi.const_get(name.to_s.camelize) }

  let(:all_creations) {
    extra_creations.inject([model_class]) { |creations, extra_name|
      creations << Vnet::Models.const_get(extra_name.to_s.camelize)
    }
  }

  it 'successfully created' do
    pre_counts = all_creations.map { |m_class| m_class.count }

    result = model

    # Ensure all 'with_lets' are touched in order to create db entries.
    with_lets.each { |let_name| send(let_name) }

    post_counts = all_creations.map { |m_class| m_class.count }
    expect(post_counts).to eq(pre_counts.map { |c| c + 1 })

    expect(result).to include(create_result)

    # TODO: Add query_filter option.
    if result[:uuid]
      query_model = model_class[result[:uuid]]
    else
      query_model = model_class[id: result[:id]]
    end

    expect(query_model).to be_model_and_include(query_result)
    expect(events).to be_event_list_of_size(create_events.size)

    create_events.each_with_index { |event, index|
      expect(events[index]).to be_event_from_model(query_model, event.first, event.last)
    }
  end
end

shared_examples 'create item on node_api with lets' do |name, let_ids: []|
  [false, true].repeated_permutation(let_ids.size).each { |permutation|
    context "with #{let_context(permutation, let_ids: let_ids)}" do
      let(:with_lets) {
        let_permutation(let_ids, permutation, '_id')
      }
      let_ids.each_with_index { |name, index|
        let("#{name}_id") { permutation[index] ? send(name).id : nil }
      }

      include_examples 'create item on node_api', name
    end
  }
end
