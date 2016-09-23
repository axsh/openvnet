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
      new_value = value_from_model(key_value.last, model)

      if new_value || value_from_model_include_nil?(key_value.last)
        new_params[key_value.first] = new_value
      end

      new_params
    }

    puts "XXXXXXXXXXXXXXXXXX #{params.inspect}"

    params.all? { |key, value|
      actual[:options].has_key?(key) && actual[:options][key] == value
    }
  end

  def value_from_model_include_nil?(value)
    case value
    when :let__interface_id, :let__segment_id
      true
    else
      false
    end
  end

  def value_from_model(value, model)
    case value
    when :model__id then model.id
    when :model__uuid then model.canonical_uuid
    when :let__interface_id then interface_id
    when :let__segment_id then segment_id
    else
      value
    end
  end

end
