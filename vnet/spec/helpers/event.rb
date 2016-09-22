# -*- coding: utf-8 -*-

RSpec::Matchers.define :be_event do |expected_type, expected_params|
  match do |actual|
    next if expected_type != actual[:event]

    expected_params.all? { |key, value|
      actual[:options].has_key?(key) && actual[:options][key] == value
    }
  end
end

RSpec::Matchers.define :be_event_from_model do |model, expected_type, expected_params|
  match do |actual|
    next if expected_type != actual[:event]

    params = expected_params.inject(expected_params.dup) { |new_params, key_value|
      new_params[key_value.first] = value_from_model(key_value.last, model)
      new_params
    }

    params.all? { |key, value|
      actual[:options].has_key?(key) && actual[:options][key] == value
    }
  end

  def value_from_model(value, model)
    case value
    when :model__id
      model.id
    when :model__uuid
      model.canonical_uuid
    else
      value
    end
  end

end
