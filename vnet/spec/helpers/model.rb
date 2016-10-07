# -*- coding: utf-8 -*-

RSpec::Matchers.define :be_model_and_include do |expected_params|
  match do |actual|
    next unless actual.is_a? Vnet::Models::Base

    expected_params.all? { |key, value|
      actual.respond_to?(key) && actual.send(key) == value
    }
  end
end
