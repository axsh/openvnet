# -*- coding: utf-8 -*-

module Vnctl::Cli
  class Datapath < Base
    namespace :datapath
    api_suffix "/api/datapaths"

    no_tasks {
      def self.add_modify_shared_options
        option_display_name
        option :open_flow_controller_uuid, :type => :string, :desc => "Openflow controller uuid for the datapath."
        option :is_connected, :type => :boolean, :desc => "Flag that detemines if the datapath is connected or not."
        option :dc_segment_id, :type => :string, :desc => "The datapath's dc segment id."
        option :node_id, :type => :string, :desc => "The node id for the datapath."
        option :ipv4_address, :type => :string, :desc => "Ipv4 address for the datapath."
        option :dpid, :type => :string, :desc => "Hexadecimal id for the datapath."
      end
    }

    option_uuid
    add_modify_shared_options
    define_add

    add_modify_shared_options
    define_modify

    define_show
    define_del
  end
end
