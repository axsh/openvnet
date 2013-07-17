# -*- coding: utf-8 -*-
class MockEventHandler
  attr_accessor :handled_events
  def initialize
    self.handled_events = []
  end
  def handle_event(event, options = {})
    self.handled_events << {event: event, :options => options}
  end
end
