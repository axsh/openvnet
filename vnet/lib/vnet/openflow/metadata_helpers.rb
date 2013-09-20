# -*- coding: utf-8 -*-

module Vnet::Openflow

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

end
