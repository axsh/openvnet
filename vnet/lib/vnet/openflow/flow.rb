# -*- coding: utf-8 -*-

module Vnet::Openflow

  module Flow

    def self.create(table_id, priority, match, actions, options = {})
      trema_hash = {
        :table_id => table_id,
        :priority => priority,
        :match => Trema::Match.new(match),
        :instructions => self.convert_instructions(actions, options),
      }
      trema_hash[:hard_timeout] = options[:hard_timeout] if options[:hard_timeout]
      trema_hash[:idle_timeout] = options[:idle_timeout] if options[:idle_timeout]
      trema_hash[:cookie] = options[:cookie] if options[:cookie]
      trema_hash[:cookie_mask] = options[:cookie_mask] if options[:cookie_mask]
      trema_hash
    end

    private

    def self.convert_instructions(actions, options)
      instructions = []
      instructions << Trema::Instructions::ApplyAction.new(:actions => self.convert_actions(actions)) if actions

      if options[:metadata]
        instructions << Trema::Instructions::WriteMetadata.new(:metadata => options[:metadata],
                                                               :metadata_mask => options[:metadata_mask])
      end

      instructions << Trema::Instructions::GotoTable.new(:table_id => options[:goto_table]) if options[:goto_table]
      instructions
    end

    def self.convert_actions(actions, result = [])
      if actions.class == Hash
        actions.each { |key,arg| result << to_action(key, arg) }
      elsif actions.class == Array
        actions.each { |arg| self.convert_actions(arg, result) }
      else
        raise("Unknown action class: #{actions.class.name}.")
      end

      result
    end

    def self.to_action(tag, arg)
      case tag
      when :eth_dst then Trema::Actions::SetField.new(:action_set => [Trema::Actions::EthDst.new(:mac_address => arg)])
      when :eth_src then Trema::Actions::SetField.new(:action_set => [Trema::Actions::EthSrc.new(:mac_address => arg)])
      when :output then Trema::Actions::SendOutPort.new(arg)
      when :tunnel_id then Trema::Actions::SetField.new(:action_set => [Trema::Actions::TunnelId.new(:tunnel_id => arg)])
      else
        raise("Unknown action type.")
      end
    end

  end

  module FlowHelpers
    include Vnet::Constants::Openflow

    #
    # Metadata helper methods:
    #
    
    def md_create(options)
      metadata = 0
      metadata_mask = 0

      options.each { |key,value|
        case key
        when :clear_route_link
          # We do not clear the routing flag as later flows might want
          # to know the packet has been routed.
          metadata = metadata | 0
          metadata_mask = metadata_mask | METADATA_VALUE_MASK
        when :flood
          metadata = metadata | OFPP_FLOOD
          metadata_mask = metadata_mask | METADATA_PORT_MASK
        when :local
          metadata = metadata | METADATA_FLAG_LOCAL
          metadata_mask = metadata_mask | METADATA_FLAG_LOCAL | METADATA_FLAG_REMOTE
        when :remote
          metadata = metadata | METADATA_FLAG_REMOTE
          metadata_mask = metadata_mask | METADATA_FLAG_LOCAL | METADATA_FLAG_REMOTE
        when :physical_network
          metadata_mask = metadata_mask | METADATA_NETWORK_MASK
        when :port
          metadata = metadata | value
          metadata_mask = metadata_mask | METADATA_PORT_MASK
        when :route_link
          metadata = metadata | value | METADATA_FLAG_ROUTING
          metadata_mask = metadata_mask | METADATA_VALUE_MASK | METADATA_FLAG_ROUTING
        when :virtual_network
          metadata = metadata | (value << METADATA_NETWORK_SHIFT)
          metadata_mask = metadata_mask | METADATA_NETWORK_MASK
        else
          raise("Unknown metadata type: #{key.inspect}")
        end
      }

      { :metadata => metadata, :metadata_mask => metadata_mask }
    end

    def md_network(type, append = nil)
      if append
        md_create(append.merge(type => self.network_number))
      else
        md_create(type => self.network_number)
      end
    end

    def md_port(append = nil)
      if append
        md_create(append.merge(:port => self.port_number))
      else
        md_create(:port => self.port_number)
      end
    end

  end

end

