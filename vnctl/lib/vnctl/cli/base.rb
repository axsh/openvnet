# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Base < Thor

    no_tasks {
      def self.option_uuid
        option :uuid, :type => :string, :desc => "Unique UUID for the #{namespace}."
      end

      def self.option_display_name
        option :display_name, :type => :string, :desc => "Human readable display name."
      end

      def self.define_add
        desc "add [OPTIONS]", "Creates a new #{namespace}."
        define_method(:add) do
          puts post(suffix, :query => options)
        end
      end

      def self.define_show
        desc "show [UUIDS]", "Shows all or a specific set of #{namespace}(s)."
        define_method(:show) do |*uuids|
          if uuids.empty?
            puts get(suffix)
          else
            uuids.each { |uuid| puts get("#{suffix}/#{uuid}") }
          end
        end
      end

      def self.define_del
        desc "del UUIDS", "Deletes one or more #{namespace}(s) separated by a space."
        define_method(:del) do |*uuids|
          puts uuids.map { |uuid|
            delete("#{suffix}/#{uuid}")
          }.join("\n")
        end
      end

      def self.define_modify
        desc "modify UUID [OPTIONS]", "Modify a #{namespace}."
        define_method(:modify) do |uuid|
          puts put("#{suffix}/#{uuid}", :query => options)
        end
      end

      def self.add_modify_shared_options(&blk)
        if block_given?
          @shared_options = blk
        else
          @shared_options.call
        end
      end

      def self.define_standard_crud_commands
        option_uuid
        add_modify_shared_options
        define_add

        add_modify_shared_options
        define_modify

        define_show
        define_del
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
