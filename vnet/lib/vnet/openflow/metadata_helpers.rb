# -*- coding: utf-8 -*-

module Vnet::Openflow

  module MetadataHelpers
    include Vnet::Constants::Openflow

    def md_create(options)
      metadata = 0
      metadata_mask = 0

      options.each { |key,value|
        case key
        when :match_value_pair_flag, :write_value_pair_flag
          metadata = metadata | (value ? METADATA_VALUE_PAIR_FLAG : 0) | METADATA_VALUE_PAIR_TYPE
          metadata_mask = metadata_mask | METADATA_VALUE_PAIR_FLAG | METADATA_VALUE_PAIR_TYPE
        when :match_value_pair_first, :write_value_pair_first
          metadata = metadata | ((value << 32) & METADATA_VALUE_PAIR_FIRST_MASK) | METADATA_VALUE_PAIR_TYPE
          metadata_mask = metadata_mask | METADATA_VALUE_PAIR_FIRST_MASK | METADATA_VALUE_PAIR_TYPE
        when :match_value_pair_second, :write_value_pair_second
          metadata = metadata | (value & METADATA_VALUE_PAIR_SECOND_MASK) | METADATA_VALUE_PAIR_TYPE
          metadata_mask = metadata_mask | METADATA_VALUE_PAIR_SECOND_MASK | METADATA_VALUE_PAIR_TYPE

        else
          raise("Unknown metadata type: #{key.inspect}")
        end
      }

      { :metadata => metadata, :metadata_mask => metadata_mask }
    end

  end

end
