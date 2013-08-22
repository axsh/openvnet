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

    desc "create [options]", "Creates a new datapath"
    option :uuid, :type => :string, :desc => "UUID for the new datapath"
    option :display_name, :type => :string, :desc => "Display name for the new datapath."
    option :ipv4_address, :type => :string, :desc => "Ipv4 address for the new datapath."
    option :datapath_id, :type => :string, :desc => "Hexadecimal id for the new datapath."
    def create
      puts Vnctl::WebApi.post("/api/#{self.class.api_suffix}", :query => options).parsed_response
    end
  end
end
