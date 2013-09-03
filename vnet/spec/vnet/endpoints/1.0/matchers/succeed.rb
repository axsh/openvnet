# -*- coding: utf-8 -*-

RSpec::Matchers.define :succeed do
  def expect_body_to_contain
    body = JSON.parse(last_response.body)
    body.merge(@contains) == body &&
    @contains.dup.delete_if { |k,v| body.has_key?(k) }.empty?
  end

  def expect_body
    body = JSON.parse(last_response.body)
    body == @expected_body
  end

  chain :with_body_containing do |contains|
    # Some times we'll get a hash with symbols in its keys but the api calls
    # always return strings. Convert all symbols to strings
    @contains = Hash[contains.map{ |k, v| [k.to_s, v] }]
  end

  chain :with_body do |expected_body|
    @expected_body = expected_body
  end

  match do |response|
    response.ok? &&
    (@contains.nil? || expect_body_to_contain) &&
    (@expected_body.nil? || expect_body)
  end

  def print_result(response)
    (@contains.nil? ? "" : "with this contained in the body:\n#{@contains.to_json}") +
    (@expected_body.nil? ? "" : "with the body:\n#{@expected_body.to_json}") +
    "\n\n" +
    "Instead we got:\n" +
    "Http status: #{response.status}\n" +
    "Body: #{response.body}" +
    (response.errors.empty? ? "" : "Stacktrace:\n #{response.errors}")
  end

  failure_message_for_should do |response|
    "We expected the last api call to succeed" + print_result(response)
  end

  failure_message_for_should_not do |response|
    "We expected the last api call not to succeed" + print_result(response)
  end
end
