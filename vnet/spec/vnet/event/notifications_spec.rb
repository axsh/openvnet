# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Event::Notifications do
  describe "handle_event" do
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
          @sleep = options.has_key?(:sleep) ? options[:sleep] : true
        end

        def handle_event(event, params)
          super
        end

        def wait_for_events_done
          sleep 0.01 while @event_queues.present?
        end

        def find_db_item(id, sleep = false)
          sleep rand / 10 if sleep
          @db_items.find{|i| i[:id] == id}
        end

        def create_item(params)
          #debug "create_item #{params.inspect}"
          db_item = find_db_item(params[:target_id], @sleep)
          return unless db_item
          return if @items[params[:target_id]]
          @items[params[:target_id]] = db_item.dup
          @executed_methods << { method: :create_item, params: params }
          debug "item_created #{params.inspect}"
        end

        def update_item(params)
          #debug "update_item #{params.inspect}"
          db_item = find_db_item(params[:target_id], @sleep)
          return unless db_item
          return unless @items[params[:target_id]]
          return if @items[params[:target_id]][:name] == db_item[:name]
          @items[params[:target_id]][:name] = db_item[:name]
          @executed_methods << { method: :update_item, params: params }
          debug "item_updated #{params.inspect}"
        end

        def delete_item(params)
          #debug "delete_item #{params.inspect}"
          db_item = find_db_item(params[:target_id], @sleep)
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

    it "updated an item" do
      item_manager = manager_class.new

      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1)

      item_manager.wait_for_events_done

      item_manager.find_db_item(1)[:name] = :bar
      notifier.publish("item_updated", target_id: 1)

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 1
      expect(item_manager.items[1][:id]).to eq 1
      expect(item_manager.items[1][:name]).to eq :bar
      expect(item_manager.executed_methods.size).to eq 2
    end

    it "create an item with updated value" do
      item_manager = manager_class.new

      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1)

      item_manager.find_db_item(1)[:name] = :bar
      notifier.publish("item_updated", target_id: 1)

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 1
      expect(item_manager.items[1][:id]).to eq 1
      expect(item_manager.items[1][:name]).to eq :bar
      expect(item_manager.executed_methods.size).to eq 1
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

    it "handle events correctly" do
      item_manager = manager_class.new(sleep: false)

      t = Thread.new do
        loop do
          ev = %w(created updated deleted).shuffle.first
          id = rand(3).to_i + 1
          notifier.publish("item_#{ev}", target_id: id)
        end
      end

      item_manager.db_items.push({ id: 1, name: :foo })
      notifier.publish("item_created", target_id: 1, actual: true)
      sleep 0.01
      item_manager.db_items.push({ id: 2, name: :bar })
      notifier.publish("item_created", target_id: 2, actual: true)
      sleep 0.01
      item_manager.db_items.push({ id: 3, name: :baz })
      notifier.publish("item_created", target_id: 3, actual: true)
      sleep 0.01
      item_manager.db_items.find{|i| i[:id] == 2}[:name] = :boo
      notifier.publish("item_updated", target_id: 2, actual: true)
      sleep 0.01
      item_manager.db_items.delete_if{|i| i[:id] == 3}
      notifier.publish("item_deleted", target_id: 3, actual: true)

      t.exit

      item_manager.wait_for_events_done

      expect(item_manager.items.size).to eq 2
      expect(item_manager.items[1]).to eq({ id: 1, name: :foo })
      expect(item_manager.items[2]).to eq({ id: 2, name: :boo })
      expect(item_manager.executed_methods.size).to eq 5
    end
  end
end
