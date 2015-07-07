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

      #
      # Metaprogramming to define common methods
      #
      def define_standard_crud_methods
        # For example class Datapath has api_suffix datapaths
        api_suffix = self.name.split("::").last.downcase + "s"

        self.class.instance_eval do
          define_method(:create) do |params = nil|
            send_request(Net::HTTP::Post, api_suffix, params)
          end

          define_method(:update) do |uuid, params = nil|
            send_request(Net::HTTP::Put, "#{api_suffix}/#{uuid}", params)
          end

          define_method(:delete) do |uuid|
            send_request(Net::HTTP::Delete, "#{api_suffix}/#{uuid}")
          end

          define_method(:show) do |uuid|
            send_request(Net::HTTP::Get, "#{api_suffix}/#{uuid}")
          end

          define_method(:index) do
            send_request(Net::HTTP::Get, api_suffix)
          end
        end
      end

    end
  end

end

