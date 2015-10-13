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

  end

end
