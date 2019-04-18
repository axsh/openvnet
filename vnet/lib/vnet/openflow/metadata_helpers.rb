# -*- coding: utf-8 -*-

module Vnet::Openflow

  module MetadataHelpers
    include Vnet::Constants::Openflow

    def md_create(options)
      metadata = 0
      metadata_mask = 0

      options.each { |key,value|
        case key
        when :match_remote, :write_remote
          metadata = metadata | (value ? METADATA_REMOTE : 0)
          metadata_mask = metadata_mask | METADATA_REMOTE
        when :match_first, :write_first
          metadata = metadata | ((value << 32) & METADATA_FIRST_MASK)
          metadata_mask = metadata_mask | METADATA_FIRST_MASK
        when :match_second, :write_second
          metadata = metadata | (value & METADATA_SECOND_MASK)
          metadata_mask = metadata_mask | METADATA_SECOND_MASK

        else
          raise("Unknown metadata type: #{key.inspect}")
        end
      }

      { :metadata => metadata, :metadata_mask => metadata_mask }
    end

  end

end
