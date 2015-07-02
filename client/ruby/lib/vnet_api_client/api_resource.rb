# -*- coding: utf-8 -*-

module VNetAPIClient

  class ApiResource
    class << self
      attr_accessor :api_uri
      attr_accessor :api_format

      def api_full_uri(suffix)
        u = ApiResource.api_uri
        f = ApiResource.api_format

        uri = "#{u}/api/1.0"
        uri += "/#{suffix}" if suffix
        uri += ".#{f}"

        URI(uri)
      end

      def send_request(verb, suffix, params = nil)
        uri = api_full_uri(suffix)
        uri.query = URI.encode_www_form(params) if params

        response = Net::HTTP.start(uri.host, uri.port) do |http|
          request = verb.new(uri.request_uri)
          http.request(request)
        end

        response_format = ApiResource.api_format.to_sym

        ResponseFormats[response_format].parse(response)
      end

    end
  end

end

