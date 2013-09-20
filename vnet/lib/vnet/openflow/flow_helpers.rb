# -*- coding: utf-8 -*-

module Vnet::Openflow

  module FlowHelpers
    include MetadataHelpers

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

    def table_network_src(network_type)
      case network_type
      when :physical then TABLE_PHYSICAL_SRC
      when :virtual  then TABLE_VIRTUAL_SRC
      else
        raise "Invalid network type value."
      end
    end

    def flow_create(type, params)
      match = {}
      match_metadata = nil
      write_metadata = nil

      case type
      when :catch_arp_lookup
        table = TABLE_ARP_LOOKUP
        priority = 20
        actions = { :output => Controller::OFPP_CONTROLLER }
        match_metadata = {
          :network => params[:network_id],
          :not_no_controller => nil
        }
      when :catch_flood_simulated
        table = TABLE_FLOOD_SIMULATED
        priority = 30
        actions = { :output => Controller::OFPP_CONTROLLER }
        match_metadata = { :network => params[:network_id] }
      when :catch_interface_simulated
        table = TABLE_INTERFACE_SIMULATED
        priority = 30
        actions = { :output => Controller::OFPP_CONTROLLER }
        match_metadata = { :interface => params[:interface_id] }
      when :catch_network_dst
        table = table_network_dst(params[:network_type])
        priority = 70
        actions = { :output => Controller::OFPP_CONTROLLER }
        match_metadata = { :network => params[:network_id] }
      when :controller_port
        table = TABLE_CONTROLLER_PORT
      when :classifier
        table = TABLE_CLASSIFIER
      when :host_ports
        table = TABLE_HOST_PORTS
      when :network_dst
        table = table_network_dst(params[:network_type])
        match_metadata = { :network => params[:network_id] }
      when :network_src
        table = table_network_src(params[:network_type])
        match_metadata = { :network => params[:network_id] }
      when :network_src_arp_drop
        table = table_network_src(params[:network_type])
        priority = 85
        match_metadata = { :network => params[:network_id] }
      when :network_src_arp_match
        table = table_network_src(params[:network_type])
        priority = 86
        match_metadata = { :network => params[:network_id] }
        goto_table = TABLE_ROUTER_CLASSIFIER
      when :router_dst_match
        table = TABLE_ROUTER_DST
        priority = 40
        match_metadata = { :network => params[:network_id] }
        goto_table = TABLE_NETWORK_DST_CLASSIFIER
      when :vif_ports_match
        table = TABLE_VIF_PORTS
        priority = 1
        write_metadata = { :network => params[:network_id] }
        goto_table = TABLE_NETWORK_SRC_CLASSIFIER
      else
        return nil
      end

      match = params[:match] if params[:match]
      match = match.merge(md_create(match_metadata)) if match_metadata

      actions = params[:actions] if params[:actions]
      priority = params[:priority] if params[:priority]
      goto_table = params[:goto_table] if params[:goto_table]

      write_metadata = params[:write_metadata] if params[:write_metadata]

      instructions = {}
      instructions[:cookie] = params[:cookie] || self.cookie
      instructions[:goto_table] = goto_table if goto_table
      instructions.merge!(md_create(write_metadata)) if write_metadata

      raise "Missing cookie." if cookie.nil?

      Flow.create(table, priority, match, actions, instructions)
    end

  end

end
