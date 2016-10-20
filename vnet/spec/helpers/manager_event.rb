# -*- coding: utf-8 -*-

RSpec::Matchers.define :be_manager_with_no_events do
  match do |manager|
    manager.instance_variable_get(:@event_queues).empty?
  end
end

RSpec::Matchers.define :be_manager_with_event_handler_state do |expected|
  match do |manager|
    manager.instance_variable_get(:@event_handler_state) == expected
  end
end
