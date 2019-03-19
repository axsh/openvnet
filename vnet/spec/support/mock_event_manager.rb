# -*- coding: utf-8 -*-

class MockEventManager
  include Celluloid
  include Vnet::Event::Notifications

  attr_accessor :db_items
  attr_reader :items, :executed_methods

  subscribe_event "item_created", :create_item
  subscribe_event "item_updated", :update_item
  subscribe_event "item_deleted", :delete_item

  def initialize
    @items = {}
    @executed_methods = []
    @db_items = []
  end

  def disable_sleep
    @disable_sleep = true
  end

  def disable_process_queue
    @disable_process_queue = true
  end

  def event_handler_process_queue(id)
    @disable_process_queue ? 'do nothing' : super
  end

  def handle_event(event, params)
    super
  end

  def wait_for_events_done
    sleep 0.01 while @event_queues.present? || @queue_statuses.present?
  end

  def find_db_item(id, sleep = false)
    sleep rand / 10 if sleep
    @db_items.find{|i| i[:id] == id}
  end

  def create_item(params)
    #debug "create_item #{params.inspect}"
    db_item = find_db_item(params[:id], !@disable_sleep)
    return unless db_item
    return if @items[params[:id]]
    @items[params[:id]] = db_item.dup
    @executed_methods << { method: :create_item, params: params }
    debug "item_created #{params.inspect}"
  end

  def update_item(params)
    #debug "update_item #{params.inspect}"
    db_item = find_db_item(params[:id], !@disable_sleep)
    return unless db_item
    return unless @items[params[:id]]
    return if @items[params[:id]][:name] == db_item[:name]
    @items[params[:id]][:name] = db_item[:name]
    @executed_methods << { method: :update_item, params: params }
    debug "item_updated #{params.inspect}"
  end

  def delete_item(params)
    #debug "delete_item #{params.inspect}"
    db_item = find_db_item(params[:id], !@disable_sleep)
    return if db_item
    return unless @items[params[:id]]
    @items.delete(params[:id])
    @executed_methods << { method: :delete_item, params: params }
    debug "item_deleted #{params.inspect}"
  end
end
