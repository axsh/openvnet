# -*- coding: utf-8 -*-

RSpec::Matchers.define :be_item_with_assoc_count do |assoc_name, expected_count|
  match do |item|
    item.send(assoc_name).count == expected_count
  end
end
