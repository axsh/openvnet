# -*- coding: utf-8 -*-

class MockEventHandler
  class << self
    cattr_accessor :handled_events
    self.handled_events = []
    def clear_handled_events
      self.handled_events.clear
    end
  end

  attr_accessor :handled_events
  def initialize
    self.handled_events = []
  end

  def handle_event(event, options = {})
    {event: event, :options => options}.tap do |ev|
      self.handled_events << ev
      self.class.handled_events << ev
    end
  end

  def async
    self
  end
end

def use_mock_event_handler
  MockEventHandler.clear_handled_events
  Vnet::Event::Dispatchable.event_handler = MockEventHandler.new
end
