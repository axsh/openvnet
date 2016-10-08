# -*- coding: utf-8 -*-

class MockEventHandler
  class << self
    cattr_accessor :handled_events
    cattr_accessor :pass_events

    self.handled_events = []

    def clear_handled_events
      self.handled_events.clear
    end
  end

  attr_accessor :handled_events

  def initialize
    self.handled_events = []
  end

  def handle_event(event, params = {})
    self.class.pass_events[event].tap { |target|
      if target
        #puts "pass event event:#{event} params:#{params}"
        target.publish(event, params)
      else
        {event: event, :options => params}.tap { |ev|
          self.handled_events << ev
          self.class.handled_events << ev
        }
      end
    }
  end

  def async
    self
  end

end

def use_mock_event_handler(pass_events = {})
  MockEventHandler.clear_handled_events
  MockEventHandler.pass_events = pass_events

  Vnet::Event::Dispatchable.event_handler = MockEventHandler.new
end
