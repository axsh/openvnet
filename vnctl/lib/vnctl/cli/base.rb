# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Base < Thor
    no_tasks {
      def self.api_suffix(suffix = nil)
        @api_suffix = suffix unless suffix.nil?
        @api_suffix
      end

      def suffix
        self.class.api_suffix
      end

      [:post, :get, :delete, :put].each { |req_type|
        define_method(req_type) { |*args| Vnctl::WebApi.send(req_type, *args).parsed_response }
      }
    }
  end
end
