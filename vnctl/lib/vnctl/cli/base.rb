# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Base < Thor

    no_tasks {
      def self.define_add(name)
        desc "add [OPTIONS]", "Creates a new #{name}."
        define_method(:add) do
          puts post(suffix, :query => options)
        end
      end

      def self.define_show(name)
        desc "show [UUIDS]", "Shows all or a specific set of #{name}."
        define_method(:show) do |*uuids|
          if uuids.empty?
            puts get(suffix)
          else
            uuids.each { |uuid| puts get("#{suffix}/#{uuid}") }
          end
        end
      end

      def self.define_del(name)
        desc "del UUIDS", "Deletes one or more networks separated by a space."
        define_method(:del) do |*uuids|
          puts uuids.map { |uuid|
            delete("#{suffix}/#{uuid}")
          }.join("\n")
        end
      end

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
