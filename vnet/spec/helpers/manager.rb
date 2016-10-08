# -*- coding: utf-8 -*-

def to_pretty_item_model(item_model)
  str = item_model.class.name
  str += '/' + item_model.canonical_uuid.to_s if item_model.canonical_uuid
  str += '/' + item_model.id.to_s if item_model.id
  str += '/' + item_model.mode.to_s if item_model.mode
end

RSpec::Matchers.define :be_manager_with_loaded do |expected|
  match do |manager|
    manager.wait_for_loaded({ id: expected[:id] }, 3.0)
  end

  failure_message do |manager|
    "expected #{manager.class.name} to be a manager with loaded #{to_pretty_item_model(expected)}"
  end

  failure_message_when_negated do |manager|
    "expected #{manager.class.name} to be a manager without loaded #{to_pretty_item_model(expected)}"
  end
end

RSpec::Matchers.define :be_manager_with_unloaded do |expected|
  match do |manager|
    manager.wait_for_unloaded({ id: expected[:id] }, 3.0)
  end

  failure_message do |manager|
    "expected #{manager.class.name} to be a manager with unloaded #{to_pretty_item_model(expected)}"
  end

  failure_message_when_negated do |manager|
    "expected #{manager.class.name} to be a manager without unloaded #{to_pretty_item_model(expected)}"
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
    "expected #{manager.class.name} to have item assoc #{item_assoc_name} with #{expected_counts} items, found #{item_assoc_counts(manager, item_assoc_name)} items"
  end

  failure_message_when_negated do |manager|
    "expected #{manager.class.name} to not have item assoc #{item_assoc_name} with #{expected_counts} items"
  end

  def item_assoc_counts(manager, item_assoc_name)
    manager.instance_variable_get(:@items).values.map { |item|
      # puts "be_manager_assocs_with_item_assoc_counts item:#{item.inspect}"

      item.send(item_assoc_name).count
    }
  end

end
