# -*- coding: utf-8 -*-

require 'spec_helper'

describe Vnet::NodeApi::InterfaceSegment do
  before(:each) { use_mock_event_handler }

  let(:interface) { Fabricate(:interface) }
  let(:segment) { Fabricate(:segment) }

  let(:if_seg_static) {
    { interface_id: interface.id,
      segment_id: segment.id,
      static: true,
      is_deleted: 0
    }
  }
  let(:if_seg_non_static) { if_seg_static.merge(static: false) }

  let(:create_mac_lease) { Fabricate(:mac_lease_free, interface_id: interface.id, segment_id: segment.id) }
  let(:create_if_seg_static) { Fabricate(:interface_segment_free, if_seg_static) }
  let(:create_if_seg_no_static) { Fabricate(:interface_segment_free, if_seg_non_static) }

  describe 'leased' do
    before(:each) { create_mac_lease }

    it 'when not static' do
      actual_result = Vnet::NodeApi::InterfaceSegment.execute(:leased, interface.id, segment.id)
      expect(actual_result).to include(if_seg_non_static)

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1

      expect(events[0][:event]).to eq Vnet::Event::INTERFACE_SEGMENT_CREATED_ITEM
      expect(events[0][:options]).to include(if_seg_non_static)
    end

    it 'when static' do
      Fabricate(:interface_segment_free, if_seg_static)

      actual_result = Vnet::NodeApi::InterfaceSegment.execute(:leased, interface.id, segment.id)
      expect(actual_result).to include(if_seg_static)

      # TODO: Add some helper methods to deal with events.
      events = MockEventHandler.handled_events
      expect(events.size).to eq 0
    end
  end

  describe 'set_static' do
    it 'with no lease' do
      actual_result = Vnet::NodeApi::InterfaceSegment.execute(:set_static, interface.id, segment.id)
      expect(actual_result).to include(if_seg_static)

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1

      expect(events[0][:event]).to eq Vnet::Event::INTERFACE_SEGMENT_CREATED_ITEM
      expect(events[0][:options]).to include(if_seg_static)
    end

    it 'with leases' do
      create_mac_lease
      if_seg = create_if_seg_no_static

      actual_result = Vnet::NodeApi::InterfaceSegment.execute(:set_static, interface.id, segment.id)
      expect(actual_result).to include(if_seg_static)

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1

      expect(events[0][:event]).to eq Vnet::Event::INTERFACE_SEGMENT_UPDATED_ITEM
      expect(events[0][:options]).to include(id: if_seg.id, static: true)
    end
  end

  describe 'clear_static' do
    it 'with no lease' do
      if_seg = create_if_seg_static

      actual_result = Vnet::NodeApi::InterfaceSegment.execute(:clear_static, interface.id, segment.id)
      expect(actual_result).to include(if_seg_non_static.merge(is_deleted: if_seg.id))

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1

      expect(events[0][:event]).to eq Vnet::Event::INTERFACE_SEGMENT_DELETED_ITEM
      expect(events[0][:options]).to include(id: if_seg.id)
    end
  end

end
