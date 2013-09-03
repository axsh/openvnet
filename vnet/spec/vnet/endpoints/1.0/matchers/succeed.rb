# -*- coding: utf-8 -*-

RSpec::Matchers.define :succeed do
  def expect_body_to_contain
    @body.merge(@contains) == @body &&
    @contains.dup.delete_if { |k,v| @body.has_key?(k) }.empty?
  end

  chain :with_body_containing do |contains|
    # Some times we'll get a hash with symbols in its keys but the api calls
    # always return strings. Convert all symbols to strings
    @contains = Hash[contains.map{ |k, v| [k.to_s, v] }]
  end

  chain :with_body do |expected_body|
    @expected_body = expected_body
  end

  chain :with_empty_body do
    @check_body_empty = true
  end

  chain :with_body_size do |size|
    @body_size = size
  end

  match do |response|
    begin
      @body = JSON.parse(last_response.body)
    rescue JSON::ParserError
      raise "Response didn't parse as JSON.\n" +
      "Response we got:\n" +
      "Http status: #{response.status}\n" +
      "Body: #{response.body}" +
      "Errors:\n #{response.errors}"
    end

    response.ok? &&
    (@contains.nil? || expect_body_to_contain) &&
    (@check_body_empty.nil? || @body.empty?) &&
    (@body_size.nil? || @body.size == @body_size) &&
    (@expected_body.nil? || @body == @expected_body)
  end

  def print_result(response)
    (@contains.nil? ? "" : "with this contained in the body:\n#{@contains.to_json}") +
    (@expected_body.nil? ? "" : "with the body:\n#{@expected_body.to_json}") +
    (@check_body_empty.nil? ? "" : "with an empty body") +
    (@body_size.nil? ? "" : "with body size: #{@body_size}") +
    "\n\n" +
    "Instead we got:\n" +
    "Http status: #{response.status}\n" +
    "Body: #{response.body}" +
    (response.errors.empty? ? "" : "Stacktrace:\n #{response.errors}")
  end

  failure_message_for_should do |response|
    "We expected the last api call to succeed " + print_result(response)
  end

  failure_message_for_should_not do |response|
    "We expected the last api call not to succeed " + print_result(response)
  end
end
