# -*- coding: utf-8 -*-

module Vnet::Models
  class InterfacePort < Base
    plugin :paranoia_is_deleted

    many_to_one :interface
    many_to_one :datapath

    dataset_module do
      def join_interface_segments
        # self.join_table(:inner, :interface_segments, interface_segments__interface_id: :interface_ports__interface_id)
        self.join(:interface_segments, interface_segments__interface_id: :interface_ports__interface_id)
      end
    end

    def validate
      super

      if singular != true && !singular.nil?
        errors.add(:singular, 'must be set to either true or null')
      end
    end

  end
end
