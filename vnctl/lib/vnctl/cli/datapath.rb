# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Datapath < Base
    namespace :datapath
    api_suffix "/api/datapaths"

    option :uuid, :type => :string, :desc => "UUID for the new datapath."
    option :open_flow_controller_uuid, :type => :string, :desc => "Openflow controller uuid for the new datapath."
    option :display_name, :type => :string, :desc => "Display name for the new datapath."
    option :is_connected, :type => :boolean, :desc => "Flag that detemines if the new datapath is connected or not."
    option :dc_segment_id, :type => :string, :desc => "The new datapath's dc segment id."
    option :node_id, :type => :string, :desc => "The node id for the new datapath."
    option :ipv4_address, :type => :string, :desc => "Ipv4 address for the new datapath."
    option :dpid, :type => :string, :desc => "Hexadecimal id for the new datapath."
    define_add

    define_show
    define_del

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
  end
end
