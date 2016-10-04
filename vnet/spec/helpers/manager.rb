# -*- coding: utf-8 -*-

RSpec::Matchers.define :be_manager_with_loaded do |expected|
  match do |manager|
    manager.wait_for_loaded({ id: expected[:id] }, 3.0)
  end

  failure_message do |manager|
    "expected #{actual.class.name} to be a manager with loaded #{expected}"
  end

  failure_message_when_negated do |manager|
    "expected #{actual.class.name} to be a manager without loaded #{expected}"
  end

end

RSpec::Matchers.define :be_manager_with_item_count do |expected_count|
  match do |manager|
    manager.instance_variable_get(:@items).count == expected_count
  end
end
