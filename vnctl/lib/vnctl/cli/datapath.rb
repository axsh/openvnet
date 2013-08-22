# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Datapath < Thor
    namespace :datapath

    no_tasks {
      def self.api_suffix(suffix = nil)
        @api_suffix = suffix unless suffix.nil?
        @api_suffix
      end
    }
    api_suffix :datapaths

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
      res = Vnctl::WebApi.post("/api/#{self.class.api_suffix}", :query => options)

      puts res.parsed_response
    end

    desc "show [uuid]", "Show one or all datapaths."
    def show(uuid = nil)
      uri = "/api/#{self.class.api_suffix}#{"/" + uuid unless uuid.nil?}"

      puts Vnctl::WebApi.get(uri).parsed_response
    end
  end
end
