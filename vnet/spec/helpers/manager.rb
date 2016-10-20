# -*- coding: utf-8 -*-

RSpec::Matchers.define :be_manager_with_loaded do |expected|
  match do |manager|
    manager.wait_for_loaded({ id: expected[:id] }, 3.0)
  end

  failure_message do |manager|
    "expected #{manager.class.name} to be a manager with loaded #{expected}"
  end

  failure_message_when_negated do |manager|
    "expected #{manager.class.name} to be a manager without loaded #{expected}"
  end
end

RSpec::Matchers.define :be_manager_with_unloaded do |expected|
  match do |manager|
    manager.wait_for_unloaded({ id: expected[:id] }, 3.0)
  end

  failure_message do |manager|
    "expected #{manager.class.name} to be a manager with unloaded #{expected}"
  end

  failure_message_when_negated do |manager|
    "expected #{manager.class.name} to be a manager without unloaded #{expected}"
  end
end

RSpec::Matchers.define :be_manager_with_item_count do |expected_count|
  match do |manager|
    item_count(manager) == expected_count
  end

  failure_message do |manager|
    "expected #{manager.class.name} to have #{expected_count} items, found #{item_count(manager)} items"
  end

  failure_message_when_negated do |manager|
    "expected #{manager.class.name} to not have #{expected_count} items"
  end

  def item_count(manager)
    manager.instance_variable_get(:@items).count
  end
end

RSpec::Matchers.define :be_manager_assocs_with_item_assoc_counts do |item_assoc_name, expected_counts|
  match do |manager|
    item_assoc_counts(manager, item_assoc_name) == expected_counts
  end

  failure_message do |manager|
    "expected #{manager.class.name} to have item asssoc #{item_assoc_name} with #{expected_counts} items, found #{item_assoc_counts(manager, item_assoc_name)} items"
  end

  failure_message_when_negated do |manager|
    "expected #{manager.class.name} to not have item asssoc #{item_assoc_name} with #{expected_counts} items"
  end

  def item_assoc_counts(manager, item_assoc_name)
    manager.instance_variable_get(:@items).values.map { |item|
      item.send(item_assoc_name).count
    }
  end
end
