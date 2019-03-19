# -*- coding: utf-8 -*-
require 'spec_helper'

shared_examples 'handle basic events' do |activate_after_publish|
  context "handle basic events #{activate_after_publish ? 'and activate event handler after publish' : 'with no state change'}" do
    it 'create an item' do
      manager.db_items.push({ id: 1, name: :foo })
      notifier.publish('item_created', id: 1)

      if activate_after_publish
        expect(manager.items).to be_empty
        manager.event_handler_active
      end

      manager.wait_for_events_done

      expect(manager.items.size).to eq 1
      expect(manager.items[1][:id]).to eq 1
      expect(manager.items[1][:name]).to eq :foo
      expect(manager.executed_methods.size).to eq 1
    end

    it 'execute create_item only once' do
      manager.db_items.push({ id: 1, name: :foo })
      notifier.publish('item_created', id: 1)
      notifier.publish('item_created', id: 1)
      notifier.publish('item_created', id: 1)

      if activate_after_publish
        expect(manager.items).to be_empty
        manager.event_handler_active
      end

      manager.wait_for_events_done

      expect(manager.items.size).to eq 1
      expect(manager.executed_methods.size).to eq 1
    end

    it 'updated an item' do
      manager.db_items.push({ id: 1, name: :foo })
      notifier.publish('item_created', id: 1)

      if activate_after_publish
        expect(manager.items).to be_empty
        manager.event_handler_active
      end

      manager.wait_for_events_done

      manager.find_db_item(1)[:name] = :bar
      notifier.publish('item_updated', id: 1)

      manager.wait_for_events_done

      expect(manager.items.size).to eq 1
      expect(manager.items[1][:id]).to eq 1
      expect(manager.items[1][:name]).to eq :bar
      expect(manager.executed_methods.size).to eq 2
    end

    it 'delete an item' do
      manager.db_items.push({ id: 1, name: :foo })
      notifier.publish('item_created', id: 1)

      if activate_after_publish
        expect(manager.items).to be_empty
        manager.event_handler_active
      end

      manager.wait_for_events_done

      manager.db_items.delete_if{|i| i[:id] == 1}
      notifier.publish('item_deleted', id: 1)

      manager.wait_for_events_done

      expect(manager.items).to be_empty
      expect(manager.executed_methods.size).to eq 2
    end

    it 'create an item and delete it' do
      manager.db_items.push({ id: 1, name: :foo })
      notifier.publish('item_created', id: 1)

      if activate_after_publish
        expect(manager.items).to be_empty
        manager.event_handler_active
      end

      manager.wait_for_events_done

      manager.db_items.delete_if{|i| i[:id] == 1}
      notifier.publish('item_deleted', id: 1)

      manager.wait_for_events_done

      expect(manager.items).to be_empty
      expect(manager.executed_methods.size).to eq 2
    end
  end
end

describe Vnet::Event::Notifications do
  let(:notifier) { Celluloid::Notifications.notifier }

  describe 'with an active manager' do
    let(:manager) do
      MockEventManager.new.tap { |manager|
        manager.event_handler_active
      }
    end

    include_examples 'handle basic events', false
  end

  describe 'with a queue-only manager' do
    let(:manager) do
      MockEventManager.new.tap { |manager|
        manager.event_handler_queue_only
      }
    end

    include_examples 'handle basic events', true

    it 'create an item should do nothing' do
      expect(manager.event_handler_state).to eq :queue_only

      manager.db_items.push({ id: 1, name: :foo })
      notifier.publish('item_created', id: 1)

      sleep 0.1

      expect(manager.items).to be_empty
    end
  end

  describe 'with a drop-all manager' do
    let(:manager) do
      MockEventManager.new
    end

    it 'create an item should do nothing' do
      expect(manager.event_handler_state).to eq :drop_all

      manager.db_items.push({ id: 1, name: :foo })
      notifier.publish('item_created', id: 1)

      sleep 0.1

      expect(manager.items).to be_empty
    end
  end

  describe 'database changes' do
    let(:manager) do
      MockEventManager.new.tap { |manager|
        manager.event_handler_active
      }
    end

    it 'handle events correctly' do
      manager.disable_sleep

      t = Thread.new do
        loop do
          ev = %w(created updated deleted).shuffle.first
          id = rand(3).to_i + 1
          notifier.publish('item_#{ev}', id: id)
        end
      end

      manager.db_items.push({ id: 1, name: :foo })
      notifier.publish('item_created', id: 1)
      sleep 0.01
      manager.db_items.push({ id: 2, name: :bar })
      notifier.publish('item_created', id: 2)
      sleep 0.01
      manager.db_items.push({ id: 3, name: :baz })
      notifier.publish('item_created', id: 3)
      sleep 0.01
      manager.db_items.find{|i| i[:id] == 2}[:name] = :boo
      notifier.publish('item_updated', id: 2)
      sleep 0.01
      manager.db_items.delete_if{|i| i[:id] == 3}
      notifier.publish('item_deleted', id: 3)

      t.exit

      manager.wait_for_events_done

      expect(manager.items.size).to eq 2
      expect(manager.items[1]).to eq({ id: 1, name: :foo })
      expect(manager.items[2]).to eq({ id: 2, name: :boo })
      expect(manager.executed_methods.size).to eq 5
    end

    it 'enqueue event to a list identified by params[:id]' do
      manager.disable_process_queue

      item_map_1 = { id: 1, name: :foo }
      item_map_2 = { id: 2, name: :bar }

      manager.db_items.push(item_map_1)
      notifier.publish('item_created', id: 1, item_map: item_map_1)
      sleep 0.01
      manager.db_items.push(item_map_2)
      notifier.publish('item_created', id: 2, item_map: item_map_2)
      sleep 0.01
      manager.db_items.find{|i| i[:id] == 2}[:name] = :baz
      notifier.publish('item_updated', id: 2)
      sleep 0.01

      event_queues = manager.instance_variable_get(:@event_queues)

      expect(event_queues[1].size).to eq 1
      expect(event_queues[2].size).to eq 2
      expect(event_queues[:default]).to be_nil
    end
  end
end
