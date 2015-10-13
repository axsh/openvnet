# -*- coding: utf-8 -*-

module Vnet::Models

  class MacRange < Base
    taggable 'mr'

    plugin :paranoia_is_deleted

    many_to_one :mac_range_group

    def_dataset_method(:containing_range) { |begin_range,end_range|
      new_dataset = self
      new_dataset = new_dataset.filter("end_mac_address >= ?", begin_range) if begin_range
      new_dataset = new_dataset.filter("begin_mac_address <= ?", end_range) if end_range
      new_dataset
    }

    def validate
      super
      errors.add(:begin_mac_address, 'invalid mac address range') unless begin_mac_address <= end_mac_address
    end

    def address_random
      block_random { |mac_address|
        MacAddress.create(mac_address: mac_address)
      }
    end

    def lease_random(interface_id)
      block_random { |mac_address|
        MacLease.create(interface_id: interface_id,
                        mac_address: mac_address)
      }
    end

    private

    def block_random(&block)
      retry_count = 20
      range_size = end_mac_address - begin_mac_address + 1

      # TODO: Fix this to ensure it always allocates an address if
      # available.
      begin
        mac_address = begin_mac_address + Random.rand(range_size)
        result = block.call(mac_address)
        
        return result if result
        
        retry_count -= 1
      end while retry_count > 0

      nil
    end

  end

end
