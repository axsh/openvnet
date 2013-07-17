# -*- coding: utf-8 -*-
module Vnet::NodeApi::Event
  module Dispatchable
    mattr_accessor :event_handler
    def dispatch_event(event, options = {})
      self.event_handler ||= DCell::Node["vnmgr"]["event_handler"]
      self.event_handler.handle_event(event, options)
    end
  end
end
