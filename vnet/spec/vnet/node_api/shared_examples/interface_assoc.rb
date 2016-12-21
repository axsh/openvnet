# -*- coding: utf-8 -*-

shared_examples 'interface assoc on node_api' do

  # TODO: Missing 'without lease'.
  describe 'update_assoc with lease' do
    before(:each) { create_lease }

    it 'when not static' do
      actual_result = node_api.execute(:update_assoc, interface.id, other.id)
      expect(actual_result).to include(if_assoc_non_static)

      events = MockEventHandler.handled_events

      expect(events).to be_event_list_of_size(1)
      expect(events[0]).to be_event(created_event_type, if_assoc_non_static)
    end

    it 'when static' do
      create_if_assoc_static

      actual_result = node_api.execute(:update_assoc, interface.id, other.id)
      expect(actual_result).to include(if_assoc_static)

      events = MockEventHandler.handled_events

      expect(events).to be_event_list_of_size(0)
    end
  end

  describe 'set_static' do
    it 'with no lease' do
      actual_result = node_api.execute(:set_static, interface.id, other.id)
      expect(actual_result).to include(if_assoc_static)

      events = MockEventHandler.handled_events

      expect(events).to be_event_list_of_size(1)
      expect(events[0]).to be_event(created_event_type, if_assoc_static)
    end

    it 'with leases' do
      create_lease
      if_seg = create_if_assoc_no_static

      actual_result = node_api.execute(:set_static, interface.id, other.id)
      expect(actual_result).to include(if_assoc_static)

      events = MockEventHandler.handled_events

      expect(events).to be_event_list_of_size(1)
      expect(events[0]).to be_event(updated_event_type, id: if_seg.id, static: true)
    end
  end

  describe 'clear_static' do
    it 'with no lease' do
      if_seg = create_if_assoc_static

      actual_result = node_api.execute(:clear_static, interface.id, other.id)
      expect(actual_result).to include(if_assoc_non_static.merge(is_deleted: if_seg.id))

      events = MockEventHandler.handled_events

      expect(events).to be_event_list_of_size(1)
      expect(events[0]).to be_event(deleted_event_type, id: if_seg.id)
    end
  end
end
