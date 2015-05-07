# -*- coding: utf-8 -*-

module Vnctl
  class WebApi
    def initialize
      @webapi_uri = Vnctl.conf.webapi_uri
      @webapi_port = Vnctl.conf.webapi_port.to_i
      @webapi_version = Vnctl.conf.webapi_version
      @output_format = Vnctl.conf.output_format

      @webapi_full_uri = "#{@webapi_uri}/api/#{@webapi_version}"
    end

    def send_request(verb, suffix, params = nil)
      uri = URI::HTTP.build(host: @webapi_full_uri,
                            path: "#{suffix}.#{@output_format}",
                            port: @webapi_port)

      uri.query = URI.encode_www_form(params) if params

      p uri
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = verb.new(uri.request_uri)
        http.request(request)
      end
    end

    def post(suffix, params = nil)
      send_request(Net::HTTP::Post, suffix, params)
    end

    def get(suffix, params = nil)
      send_request(Net::HTTP::Get, suffix, params)
    end

    def put(suffix, params = nil)
      send_request(Net::HTTP::Put, suffix, params)
    end

    def delete(suffix, params = nil)
      send_request(Net::HTTP::Delete, suffix, params)
    end
  end
end
