# -*- coding: utf-8 -*-

require_relative "helper_methods"

RSpec::Matchers.define :fail do
  include EndpointMatcherHelper

  def expect_call_to_fail
    !@response.ok?
  end

  def expect_code
    @code.nil? || @response.status == @code
  end

  def expect_error
    @error_details.nil? || (
      body = JSON.parse(last_response.body)

      (body["error"] == @error_details[:name] ||
      body["error"] == "Vnet::Endpoints::Errors::#{@error_details[:name]}") &&
      verify_message(@error_details[:message], body["message"])
    )
  end

  chain :with_code do |code|
    @code = code
  end

  chain :with_error do |error_name, message = nil|
    @error_details = {:name => error_name, :message => message}
  end

  match do |response|
    @response = response
    expect_call_to_fail && expect_code && expect_error
  end

  def print_expectation
    "Http status: " + (@code ? @code.to_s : "any") + "\n" +
    "Error: " + (@error_details ? @error_details[:name] : "any") + "\n" +
    "message: " + (
      (@error_details && @error_details[:message]) ? @error_details[:message] : "any"
    ).to_s
  end

  failure_message do |response|
    "We expected:\n" +
    print_expectation +
    "\n\n" +
    "Instead we got:\n" +
    print_response(response)
  end

  failure_message_when_negated do |response|
    "We got exactly what we didn't expect.\n" + print_expectation +
    "\nComplete response:\n" + print_response(response)
  end
end
