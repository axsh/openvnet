# -*- coding: utf-8 -*-

module Vnet::Openflow

  module FlowHelpers
    include MetadataHelpers

    Flow = Vnet::Openflow::Flow

    FLOW_MATCH_METADATA_PARAMS = [:match_datapath,
                                  :match_dp_network,
                                  :match_dp_route_link,
                                  :match_ignore_mac2mac,
                                  :match_interface,
                                  :match_local,
                                  :match_mac2mac,
                                  :match_network,
                                  :match_not_no_controller,
                                  :match_reflection,
                                  :match_remote,
                                  :match_route_link,
                                  :match_tunnel,
                                  :match_value_pair_flag,
                                  :match_value_pair_first,
                                  :match_value_pair_second,
                                 ]
    FLOW_WRITE_METADATA_PARAMS = [:clear_all,
                                  :write_datapath,
                                  :write_dp_network,
                                  :write_dp_route_link,
                                  :write_ignore_mac2mac,
                                  :write_interface,
                                  :write_local,
                                  :write_mac2mac,
                                  :write_network,
                                  :write_no_controller,
                                  :write_not_no_controller,
                                  :write_reflection,
                                  :write_remote,
                                  :write_route_link,
                                  :write_tunnel,
                                  :write_value_pair_flag,
                                  :write_value_pair_first,
                                  :write_value_pair_second,
                                 ]

    def is_ipv4_broadcast(address, prefix)
      address == IPV4_ZERO && prefix == 0
    end

    def match_ipv4_subnet_dst(address, prefix)
      if is_ipv4_broadcast(address, prefix)
        { :eth_type => 0x0800 }
      else
        { :eth_type => 0x0800,
          :ipv4_dst => address,
          :ipv4_dst_mask => IPV4_BROADCAST << (32 - prefix)
        }
      end
    end

    def match_ipv4_subnet_src(address, prefix)
      if is_ipv4_broadcast(address, prefix)
        { :eth_type => 0x0800 }
      else
        { :eth_type => 0x0800,
          :ipv4_src => address,
          :ipv4_src_mask => IPV4_BROADCAST << (32 - prefix)
        }
      end
    end

    def table_network_dst(network_type)
      case network_type
      when :physical then TABLE_PHYSICAL_DST
      when :virtual  then TABLE_VIRTUAL_DST
      else
        raise "Invalid network type value."
      end
    end

    def flow_create(type, params)
      match = {}
      match_metadata = {}
      write_metadata = {}

      case type
      when :router_dst_match
        table = TABLE_ARP_TABLE
        priority = 40
        match_metadata = { :network => params[:network_id] }
        goto_table = TABLE_NETWORK_DST_CLASSIFIER

      #
      # Refactored:
      #
      when :default
      when :drop
        priority = 90
      when :controller
        actions = { :output => Controller::OFPP_CONTROLLER }
      when :controller_classifier
        table = TABLE_CONTROLLER_PORT
        write_metadata = { :interface => params[:write_interface_id] }
        goto_table = TABLE_INTERFACE_EGRESS_CLASSIFIER
      when :interface_classifier
        table = TABLE_INTERFACE_EGRESS_CLASSIFIER
        match_metadata = { :interface => params[:interface_id] }
        write_metadata = { :network => params[:write_network_id] }
        goto_table = TABLE_INTERFACE_EGRESS_FILTER
      when :router_classifier
        table = TABLE_ROUTE_INGRESS_INTERFACE
        match_metadata = { :network => params[:network_id] }
        if params[:ingress_interface_id]
          priority = 10
          write_metadata = { :interface => params[:ingress_interface_id] }
          goto_table = TABLE_ROUTE_INGRESS_TRANSLATION
        else
          priority = 20
          goto_table = TABLE_NETWORK_DST_CLASSIFIER
        end
      when :routing
        priority = params[:default_route] ? 20 : 30
      else
        return nil
      end

      #
      # Generic:
      #
      table = params[:table] if params[:table]
      actions = params[:actions] if params[:actions]
      priority = params[:priority] if params[:priority]
      goto_table = params[:goto_table] if params[:goto_table]

      if params.has_key?(:table_network_dst)
        table = table_network_dst(params[:table_network_dst])
      end

      #
      # Match/Write Metadata options:
      #
      FLOW_MATCH_METADATA_PARAMS.each { |type|
        match_metadata[type] = params[type] if params.has_key? type
      }
      FLOW_WRITE_METADATA_PARAMS.each { |type|
        write_metadata[type] = params[type] if params.has_key? type
      }

      #
      # Output:
      #
      match_metadata = match_metadata.merge!(params[:match_metadata]) if params[:match_metadata]
      write_metadata = write_metadata.merge!(params[:write_metadata]) if params[:write_metadata]

      match = match.merge!(params[:match]) if params[:match]
      match = match.merge!(md_create(match_metadata)) if !match_metadata.empty?

      instructions = {}
      instructions[:cookie] = params[:cookie] || self.cookie
      instructions[:goto_table] = goto_table if goto_table

      instructions[:hard_timeout] = params[:hard_timeout] if params[:hard_timeout]
      instructions[:idle_timeout] = params[:idle_timeout] if params[:idle_timeout]

      instructions.merge!(md_create(write_metadata)) if !write_metadata.empty?

      raise "Missing cookie." if instructions[:cookie].nil?

      instructions[:idle_timeout] = params[:idle_timeout] if params[:idle_timeout]
      instructions[:hard_timeout] = params[:hard_timeout] if params[:hard_timeout]

      Flow.create(table, priority, match, actions, instructions)
    end

    def flows_for_filtering_mac_address(flows, mac_address, use_cookie = self.cookie)
      flows << flow_create(:drop,
                           table: TABLE_NETWORK_SRC_CLASSIFIER,
                           match: {
                             :eth_dst => mac_address
                           },
                           cookie: use_cookie)
      flows << flow_create(:drop,
                           table: TABLE_NETWORK_SRC_CLASSIFIER,
                           match: {
                             :eth_src => mac_address
                           },
                           cookie: use_cookie)
      flows << flow_create(:drop,
                           table: TABLE_NETWORK_DST_CLASSIFIER,
                           match: {
                             :eth_dst => mac_address
                           },
                           cookie: use_cookie)
      flows << flow_create(:drop,
                           table: TABLE_NETWORK_DST_CLASSIFIER,
                           match: {
                             :eth_src => mac_address
                           },
                           cookie: use_cookie)
    end

  end

end
