# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Datapath < Base
    namespace :datapath
    api_suffix "/api/datapaths"

    desc "add [options]", "Creates a new datapath."
    option :uuid, :type => :string, :desc => "UUID for the new datapath."
    option :open_flow_controller_uuid, :type => :string, :desc => "Openflow controller uuid for the new datapath."
    option :display_name, :type => :string, :desc => "Display name for the new datapath."
    option :is_connected, :type => :boolean, :desc => "Flag that detemines if the new datapath is connected or not."
    option :dc_segment_id, :type => :string, :desc => "The new datapath's dc segment id."
    option :node_id, :type => :string, :desc => "The node id for the new datapath."
    option :ipv4_address, :type => :string, :desc => "Ipv4 address for the new datapath."
    option :dpid, :type => :string, :desc => "Hexadecimal id for the new datapath."
    def add
      puts post(suffix, :query => options)
    end

    desc "show [UUIDS]", "Shows all or a specific set of datapaths."
    def show(*uuids)
      if uuids.empty?
        puts get(suffix)
      else
        uuids.each { |uuid| puts get("#{suffix}/#{uuid}") }
      end
    end

    desc "modify UUID [OPTIONS]", "Modify a datapath."
    option :open_flow_controller_uuid, :type => :string, :desc => "Openflow controller uuid for the datapath."
    option :display_name, :type => :string, :desc => "Display name for the datapath."
    option :is_connected, :type => :boolean, :desc => "Flag that detemines if the datapath is connected or not."
    option :dc_segment_id, :type => :string, :desc => "The datapath's dc segment id."
    option :node_id, :type => :string, :desc => "The node id for the datapath."
    option :ipv4_address, :type => :string, :desc => "Ipv4 address for the datapath."
    option :dpid, :type => :string, :desc => "Hexadecimal id for the datapath."
    def modify(uuid)
      puts put("#{suffix}/#{uuid}", :query => options)
    end

    desc "del UUIDS", "Deletes one or more datapaths separated by a space."
    def del(*uuids)
      uuids.each { |uuid|
        puts delete("#{suffix}/#{uuid}")
      }
    end
  end
end
