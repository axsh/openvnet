# -*- coding: utf-8 -*-

module EndpointMatcherHelper
  def verify_message(expected, actual)
    case expected
    when nil
      true
    when Regexp
       expected =~ actual
    else
     expected == actual
    end
  end

  def print_response(response)
    "Http status: #{response.status}\n" +
    "Body: #{response.body.split(/\n/).slice(0, 100).join("\n")}\n" +
    (response.errors.empty? ? "" : "Stacktrace:\n #{response.errors}")
  end
end
