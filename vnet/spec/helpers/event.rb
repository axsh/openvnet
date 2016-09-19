# -*- coding: utf-8 -*-

RSpec::Matchers.define :be_event do |expected_type, expected_params|
  match do |actual|
    next if expected_type != actual[:event]

    expected_params.all? { |key, value|
      actual[:options].has_key?(key) && actual[:options][key] == value
    }
  end
end
