# -*- coding: utf-8 -*-

module Vnet::Openflow

  class Flow

    attr_reader :params

    def initialize(table_id, priority, match, actions, options = {})
      @params = {
        :table_id => table_id,
        :priority => priority,
        :match => match,
        :actions => actions,
        :options => options
      }
    end

    def to_trema_hash
      trema_hash = {
        :table_id => @params[:table_id],
        :priority => @params[:priority],
        :match => Trema::Match.new(@params[:match]),
        :instructions => convert_instructions(@params[:actions], @params[:options]),
      }
      trema_hash[:hard_timeout] = @params[:options][:hard_timeout] if @params[:options][:hard_timeout]
      trema_hash[:idle_timeout] = @params[:options][:idle_timeout] if @params[:options][:idle_timeout]
      trema_hash[:cookie] = @params[:options][:cookie] if @params[:options][:cookie]
      trema_hash[:cookie_mask] = @params[:options][:cookie_mask] if @params[:options][:cookie_mask]
      trema_hash
    end

    def ==(flow)
      flow == params
    end

    def self.create(table_id, priority, match, actions, options = {})
      self.new(table_id, priority, match, actions, options)
    end

    def convert_instructions(actions, options)
      instructions = []

      if actions
        instructions << Trema::Instructions::ApplyAction.new(:actions => self.convert_actions(actions))
      end

      if options[:metadata]
        instructions << Trema::Instructions::WriteMetadata.new(:metadata => options[:metadata],
                                                               :metadata_mask => options[:metadata_mask])
      end

      if options[:goto_table]
        instructions << Trema::Instructions::GotoTable.new(:table_id => options[:goto_table])
      end

      if instructions.empty?
        # Make sure there's always at least one instruction included.
        instructions << Trema::Instructions::ApplyAction.new(:actions => [])
      end

      instructions
    end

    def convert_actions(actions, result = [])
      if actions.class == Hash
        actions.each { |key,arg| result << to_action(key, arg) }
      elsif actions.class == Array
        actions.each { |arg| self.convert_actions(arg, result) }
      else
        raise("Unknown action class: #{actions.class.name}.")
      end

      result
    end

    def to_action(tag, arg)
      case tag
      when :eth_dst then Trema::Actions::SetField.new(:action_set => [Trema::Actions::EthDst.new(:mac_address => arg)])
      when :eth_src then Trema::Actions::SetField.new(:action_set => [Trema::Actions::EthSrc.new(:mac_address => arg)])
      when :normal then Trema::Actions::SendOutPort.new(:port_number => OFPP_NORMAL)
      when :output then Trema::Actions::SendOutPort.new(:port_number => arg)
      when :tunnel_id then Trema::Actions::SetField.new(:action_set => [Trema::Actions::TunnelId.new(:tunnel_id => arg)])
      when :strip_vlan then Trema::Actions::PopVlan.new if arg == true # TODO refactoring
      else
        raise("Unknown action type.")
      end
    end

  end

  module MetadataHelpers
    include Vnet::Constants::Openflow

    def md_create(options)
      metadata = 0
      metadata_mask = 0

      options.each { |key,value|
        case key
        when :clear_all
          metadata_mask = 0xffffffffffffffff
        when :collection
          metadata = metadata | value | METADATA_TYPE_COLLECTION
          metadata_mask = metadata_mask | METADATA_VALUE_MASK | METADATA_TYPE_MASK
        when :datapath
          metadata = metadata | value | METADATA_TYPE_DATAPATH
          metadata_mask = metadata_mask | METADATA_VALUE_MASK | METADATA_TYPE_MASK
        when :interface
          metadata = metadata | value | METADATA_TYPE_INTERFACE
          metadata_mask = metadata_mask | METADATA_VALUE_MASK | METADATA_TYPE_MASK
        when :local
          metadata = metadata | METADATA_FLAG_LOCAL
          metadata_mask = metadata_mask | METADATA_FLAG_LOCAL | METADATA_FLAG_REMOTE
        when :mac2mac
          metadata = metadata | METADATA_FLAG_MAC2MAC
          metadata_mask = metadata_mask | METADATA_FLAG_MAC2MAC
        when :network
          metadata = metadata | value | METADATA_TYPE_NETWORK
          metadata_mask = metadata_mask | METADATA_VALUE_MASK | METADATA_TYPE_MASK
        when :no_controller
          metadata = metadata | METADATA_FLAG_NO_CONTROLLER
          metadata_mask = metadata_mask | METADATA_FLAG_NO_CONTROLLER
        when :not_no_controller
          metadata = metadata
          metadata_mask = metadata_mask | METADATA_FLAG_NO_CONTROLLER
        when :remote
          metadata = metadata | METADATA_FLAG_REMOTE
          metadata_mask = metadata_mask | METADATA_FLAG_LOCAL | METADATA_FLAG_REMOTE
        when :reflection
          metadata = metadata | METADATA_FLAG_REFLECTION
          metadata_mask = metadata_mask | METADATA_FLAG_REFLECTION
        when :route
          metadata = metadata | value | METADATA_TYPE_ROUTE
          metadata_mask = metadata_mask | METADATA_VALUE_MASK | METADATA_TYPE_MASK
        when :route_link
          metadata = metadata | value | METADATA_TYPE_ROUTE_LINK
          metadata_mask = metadata_mask | METADATA_VALUE_MASK | METADATA_TYPE_MASK
        when :tunnel
          metadata = metadata | METADATA_FLAG_TUNNEL
          metadata_mask = metadata_mask | METADATA_FLAG_TUNNEL
        when :vif
          metadata = metadata | METADATA_FLAG_VIF
          metadata_mask = metadata_mask | METADATA_FLAG_VIF
        else
          raise("Unknown metadata type: #{key.inspect}")
        end
      }

      { :metadata => metadata, :metadata_mask => metadata_mask }
    end

    def md_network(type, append = nil)
      if append
        md_create(append.merge(type => self.network_id))
      else
        md_create(type => self.network_id)
      end
    end

    def md_port(append = nil)
      if append
        md_create(append.merge(:port => self.port_number))
      else
        md_create(:port => self.port_number)
      end
    end

    def md_has_flag(flag, value, mask = nil)
      mask = value if mask.nil?
      (value & (mask & flag)) == flag
    end
    
    def md_to_id(type, metadata)
      type_value = case type
                   when :network then METADATA_TYPE_NETWORK
                   when :interface then METADATA_TYPE_INTERFACE
                   else
                     return nil
                   end
      
      if metadata.nil? || (metadata & METADATA_TYPE_MASK) != type_value
        return nil
      end
      
      metadata & METADATA_VALUE_MASK
    end

  end

  module FlowHelpers
    include MetadataHelpers

    # Add Flow to the namespace of classes outside of Vnet::Openflow.
    Flow = Flow

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

