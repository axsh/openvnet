# -*- coding: utf-8 -*-

# 'delete_events': Array of events after deletion.
# 'delete_filter': Filter used when calling delete on node_api.
# 'delete_item': Item to be deleted.
# 'events': Should be 'MockEventHandler.handled_events'.

# TODO: Add block that allows the caller to include additional tests. (?)

# TODO: Check if there are event params we're not testing for.

shared_examples 'delete item on node_api' do |name, extra_deletions = []|
  let(:model_class) { Vnet::Models.const_get(name.to_s.camelize) }
  let(:nodeapi_class) { Vnet::NodeApi.const_get(name.to_s.camelize) }

  let(:all_deletions) {
    extra_deletions.inject([model_class]) { |deletions, extra_name|
      deletions << Vnet::Models.const_get(extra_name.to_s.camelize)
    }
  }

  it 'successfully deleted' do
    delete_item

    # TODO: Verify result of destroy.
    pre_counts = all_deletions.map { |m_class| m_class.count }
    nodeapi_class.execute(:destroy, delete_filter)
    post_counts = all_deletions.map { |m_class| m_class.count }

    expect(post_counts).to eq(pre_counts.map { |c| c - 1 })
    expect(events.size).to eq(delete_events.size)

    delete_events.each_with_index { |event, index|
      expect(events[index]).to be_event(event.first, event.last)
    }
  end
end
