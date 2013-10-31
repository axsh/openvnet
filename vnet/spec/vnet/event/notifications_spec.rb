# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Event::Notifications do
  describe "handle_event without options" do
    let(:notifier) { Celluloid::Notifications.notifier }

    let(:manager_class) do
      Class.new do
        include Celluloid
        include Vnet::Event::Notifications

        attr_accessor :db_items
        attr_reader :items, :executed_methods

        subscribe_event "item_created", :create_item
        subscribe_event "item_updated", :update_item
        subscribe_event "item_deleted", :delete_item

        def initialize(options = {})
          @items = {}
          @executed_methods = []
          @db_items = []
          @sleep_after_find_db_item = options[:sleep_after_find_db_item]
        end

        def wait_for_events_done
          sleep 0.1 while @event_queues.present?
        end

        def find_db_item(id)
          @db_items.find{|i| i[:id] == id}
        end

        def create_item(params)
          debug "create_item #{params.inspect}"
          sleep rand unless @sleep_after_find_db_item
          db_item = find_db_item(params[:target_id])
          sleep rand if @sleep_after_find_db_item
          return unless db_item
          return if @items[params[:target_id]]
          @items[params[:target_id]] = db_item.dup
          @executed_methods << { method: :create_item, params: params }
          debug "item_created #{params.inspect}"
        end

        def update_item(params)
          debug "update_item #{params.inspect}"
          sleep rand
          db_item = find_db_item(params[:target_id])
          return unless db_item
          return unless @items[params[:target_id]]
          @items[params[:target_id]][:name] = db_item[:name]
          @executed_methods << { method: :update_item, params: params }
          debug "item_updated #{params.inspect}"
        end

        def delete_item(params)
          debug "delete_item #{params.inspect}"
          sleep rand
          db_item = find_db_item(params[:target_id])
          return if db_item
          return unless @items[params[:target_id]]
          @items.delete(params[:target_id])
          @executed_methods << { method: :delete_item, params: params }
          debug "item_deleted #{params.inspect}"
        end
      end
    end

    it "create an item" do
      item_manager = manager_class.new

      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1)

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 1
      expect(item_manager.items[1][:id]).to eq 1
      expect(item_manager.items[1][:name]).to eq :foo
      expect(item_manager.executed_methods.size).to eq 1
    end

    it "execute create_item only once" do
      item_manager = manager_class.new

      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1)
      notifier.publish("item_created", target_id: 1)
      notifier.publish("item_created", target_id: 1)

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 1
      expect(item_manager.executed_methods.size).to eq 1
    end

    it "updated an item twice" do
      item_manager = manager_class.new

      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1)

      item_manager.find_db_item(1)[:name] = :bar
      notifier.publish("item_updated", target_id: 1)

      item_manager.find_db_item(1)[:name] = :baz
      notifier.publish("item_updated", target_id: 1)

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 1
      expect(item_manager.items[1][:id]).to eq 1
      expect(item_manager.items[1][:name]).to eq :baz
      expect(item_manager.executed_methods.size).to eq 3
    end

    it "delete an item" do
      item_manager = manager_class.new

      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1)

      item_manager.wait_for_events_done

      item_manager.db_items.delete_if{|i| i[:id] == 1}
      notifier.publish("item_deleted", target_id: 1)

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 0
      expect(item_manager.executed_methods.size).to eq 2
    end

    it "create an item and delete it" do
      item_manager = manager_class.new(sleep_after_find_db_item: true)

      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1)

      item_manager.wait_for_events_done

      item_manager.db_items.delete_if{|i| i[:id] == 1}
      notifier.publish("item_deleted", target_id: 1)

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 0
      expect(item_manager.executed_methods.size).to eq 2
    end

    it "does not create any item" do
      item_manager = manager_class.new

      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1)

      item_manager.db_items.delete_if{|i| i[:id] == 1}
      notifier.publish("item_deleted", target_id: 1)

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 0
      expect(item_manager.executed_methods.size).to eq 0
    end

    it "ignore events if status is invalid" do
      item_manager = manager_class.new

      notifier.publish("item_updated", target_id: 1)
      notifier.publish("item_deleted", target_id: 1)
      notifier.publish("item_updated", target_id: 2)
      notifier.publish("item_deleted", target_id: 2)
      notifier.publish("item_created", target_id: 3)
      notifier.publish("item_updated", target_id: 3)
      notifier.publish("item_deleted", target_id: 3)

      # will be processed
      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1, expected: true)

      notifier.publish("item_created", target_id: 1)
      notifier.publish("item_deleted", target_id: 1)
      notifier.publish("item_updated", target_id: 2)
      notifier.publish("item_deleted", target_id: 2)
      notifier.publish("item_created", target_id: 3)
      notifier.publish("item_updated", target_id: 3)
      notifier.publish("item_deleted", target_id: 3)

      # will be processed
      item_manager.find_db_item(1)[:name] = :bar
      notifier.publish("item_updated", target_id: 1, expected: true)

      notifier.publish("item_created", target_id: 1)
      notifier.publish("item_deleted", target_id: 1)
      notifier.publish("item_updated", target_id: 2)
      notifier.publish("item_deleted", target_id: 2)
      notifier.publish("item_created", target_id: 3)
      notifier.publish("item_updated", target_id: 3)
      notifier.publish("item_deleted", target_id: 3)

      # will be processed
      item_manager.db_items.push({ id: 2, name: :foo })
      notifier.publish("item_created", target_id: 2, expected: true)

      notifier.publish("item_created", target_id: 1)
      notifier.publish("item_deleted", target_id: 1)
      notifier.publish("item_created", target_id: 2)
      notifier.publish("item_deleted", target_id: 2)
      notifier.publish("item_created", target_id: 3)
      notifier.publish("item_updated", target_id: 3)
      notifier.publish("item_deleted", target_id: 3)

      item_manager.wait_for_events_done

      # will be processed
      item_manager.db_items.delete_if{|i| i[:id] == 1}
      notifier.publish("item_deleted", target_id: 1, expected: true)

      notifier.publish("item_created", target_id: 1)
      notifier.publish("item_updated", target_id: 1)
      notifier.publish("item_deleted", target_id: 1)
      notifier.publish("item_created", target_id: 2)
      notifier.publish("item_deleted", target_id: 2)
      notifier.publish("item_updated", target_id: 3)
      notifier.publish("item_deleted", target_id: 3)

      # will be processed
      item_manager.find_db_item(2)[:name] = :bar
      notifier.publish("item_updated", target_id: 2, expected: true)

      notifier.publish("item_created", target_id: 1)
      notifier.publish("item_updated", target_id: 1)
      notifier.publish("item_deleted", target_id: 1)
      notifier.publish("item_created", target_id: 2)
      notifier.publish("item_deleted", target_id: 2)
      notifier.publish("item_updated", target_id: 3)
      notifier.publish("item_deleted", target_id: 3)

      item_manager.db_items.push({ id: 3, name: :foo })
      notifier.publish("item_created", target_id: 3)

      notifier.publish("item_created", target_id: 1)
      notifier.publish("item_updated", target_id: 1)
      notifier.publish("item_deleted", target_id: 1)
      notifier.publish("item_created", target_id: 2)
      notifier.publish("item_deleted", target_id: 2)
      notifier.publish("item_created", target_id: 3)

      item_manager.db_items.delete_if{|i| i[:id] == 3}
      notifier.publish("item_deleted", target_id: 3)

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 1
      expect(item_manager.items).to eq({ 2 => { id: 2, name: :bar } })
      expect(item_manager.executed_methods.size).to eq 5
      expect(item_manager.executed_methods.all?{|m| m[:params][:expected]}).to eq true
    end
  end
end
