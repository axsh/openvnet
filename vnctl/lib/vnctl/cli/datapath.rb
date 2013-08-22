# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Datapath < Thor
    namespace :datapath

    no_tasks {
      def self.api_suffix(suffix = nil)
        @api_suffix = suffix unless suffix.nil?
        @api_suffix
      end

      def suffix
        self.class.api_suffix
      end

      [:post, :get, :delete].each { |req_type|
        define_method(req_type) { |*args| Vnctl::WebApi.send(req_type, *args).parsed_response }
      }
    }
    api_suffix "/api/datapaths"

    desc "create [options]", "Creates a new datapath."
    option :uuid, :type => :string, :desc => "UUID for the new datapath."
    option :open_flow_controller_uuid, :type => :string, :desc => "Openflow controller uuid for the new datapath."
    option :display_name, :type => :string, :desc => "Display name for the new datapath."
    option :is_connected, :type => :boolean, :desc => "Flag that detemines if the new datapath is connected or not."
    option :dc_segment_id, :type => :string, :desc => "The new datapath's dc segment id."
    option :node_id, :type => :string, :desc => "The node id for the new datapath."
    option :ipv4_address, :type => :string, :desc => "Ipv4 address for the new datapath."
    option :datapath_id, :type => :string, :desc => "Hexadecimal id for the new datapath."
    def create
      puts post(suffix, :query => options)
    end

    desc "show [UUID]", "Show one or all datapaths."
    def show(uuid = nil)
      puts get(suffix + (uuid.nil? ? "" : "/#{uuid}"))
    end

    desc "del UUIDS", "Delete one or more datapaths separated by a space."
    def del(*uuids)
      uuids.each { |uuid|
        puts delete("suffix/#{uuid}")
      }
    end
  end
end
