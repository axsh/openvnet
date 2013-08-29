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
      else
        raise("Unknown action type.")
      end
    end

  end

  module FlowHelpers
    include Vnet::Constants::Openflow

    # Add Flow to the namespace of classes outside of Vnet::Openflow.
    Flow = Flow

    #
    # Metadata helper methods:
    #

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
        when :flood
          metadata = metadata | METADATA_FLAG_FLOOD
          metadata_mask = metadata_mask | METADATA_FLAG_FLOOD
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
        when :physical
          metadata = metadata | METADATA_FLAG_PHYSICAL
          metadata_mask = metadata_mask | METADATA_FLAG_VIRTUAL | METADATA_FLAG_PHYSICAL
        when :physical_network
          metadata = metadata | value | METADATA_TYPE_NETWORK | METADATA_FLAG_PHYSICAL
          metadata_mask = metadata_mask | METADATA_VALUE_MASK | METADATA_TYPE_MASK | METADATA_FLAG_VIRTUAL | METADATA_FLAG_PHYSICAL
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
        when :virtual
          metadata = metadata | METADATA_FLAG_VIRTUAL
          metadata_mask = metadata_mask | METADATA_FLAG_VIRTUAL | METADATA_FLAG_PHYSICAL
        when :virtual_network
          metadata = metadata | value | METADATA_TYPE_NETWORK | METADATA_FLAG_VIRTUAL
          metadata_mask = metadata_mask | METADATA_VALUE_MASK | METADATA_TYPE_MASK | METADATA_FLAG_VIRTUAL | METADATA_FLAG_PHYSICAL
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

  end

end

