# -*- coding: utf-8 -*-

module Vnet::Event
  module Dispatchable
    mattr_accessor :event_handler

    def dispatch_event(event, options = {})
      self.event_handler ||= _find_event_handler
      self.event_handler.async.handle_event(event, options)
    end

    def _find_event_handler
      event_handler_node_id = DCell::Global[:event_handler_node_id] or raise "event_handler_node_id not found in DCell::Global"
      event_handler_node = DCell::Node[event_handler_node_id] or raise "node '#{event_handler_node_id}' with event_handler not found"
      event_handler_node[:event_handler] or raise "event_handler actor on node '#{event_handler_node_id}' not found"
    end
  end
end
