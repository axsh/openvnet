# -*- coding: utf-8 -*-
module Vnet::Event
  module Dispatchable
    mattr_accessor :event_handler

    def dispatch_event(event, options = {})
      self.event_handler ||= _find_event_handler
      self.event_handler.handle_event(event, options)
    end

    def _find_event_handler
      DCell::Global[:event_handler] or raise "event_hander not found in DCell::Global"
    end
  end
end
