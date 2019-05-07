# -*- coding: utf-8 -*-

module Vnet::Event
  module Dispatchable
    mattr_accessor :event_handler

    def dispatch_event(event, options = {})
      self.event_handler ||= Vnet::get_node_actor('vnmgr', :event_handler)
      self.event_handler.async.handle_event(event, options)
    end

  end
end
