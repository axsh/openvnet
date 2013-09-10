# -*- coding: utf-8 -*-

module EndpointMatcherHelper
  def print_response(response)
    "Http status: #{response.status}\n" +
    "Body: #{response.body}\n" +
    (response.errors.empty? ? "" : "Stacktrace:\n #{response.errors}")
  end
end
