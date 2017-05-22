# -*- coding: utf-8 -*-

module Vnet::Models
  class Segment < Base
    taggable 'seg'
    plugin :paranoia_is_deleted

    use_modes Vnet::Constants::Segment::MODES

    one_to_many :networks

    one_to_many :datapath_segments
    one_to_many :interface_segments
    one_to_many :topology_segments

    one_to_many :mac_addresses
    # Really a one to many relation but we're using many_to_many so sequel will let us use a join table
    many_to_many :mac_leases, :join_table => :mac_addresses,
                              :left_key => :segment_id,
                              :left_primary_key => :id,
                              :right_key => :id,
                              :right_primary_key => :mac_address_id,
                              :conditions => "mac_leases.deleted_at is null"

    plugin :association_dependencies,
    # 0010_segment
    datapath_segments: :destroy,
    networks: :destroy,
    topology_segments: :destroy,
    # 0011_assoc_interface
    interface_segments: :destroy

    def before_destroy
      # the association_dependencies plugin doesn't allow us to destroy because it's a many to many relation
      self.mac_leases.each { |lease| lease.destroy }

      super
    end

  end
end
