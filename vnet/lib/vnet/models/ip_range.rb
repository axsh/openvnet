# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class IpRange < Base
    taggable 'ipr'

    many_to_one :ip_range_group

    plugin :paranoia_is_deleted

    def_dataset_method(:containing_range) { |begin_range,end_range|
      new_dataset = self
      new_dataset = new_dataset.filter("end_ipv4_address >= ?", begin_range) if begin_range
      new_dataset = new_dataset.filter("begin_ipv4_address <= ?", end_range) if end_range
      new_dataset
    }

    def available_ip(network_id, from, to, order)
      case order
      when :asc
        boundaries = IpAddress.leased_ip_bound_lease(network_id, from, to).limit(2).all
        get_assignment_ip(boundaries, from, to)
      when :desc
        boundaries = IpAddress.leased_ip_bound_lease(network_id, from, to).order(:ip_addresses__ipv4_address.desc).limit(2).all
        get_assignment_ip(boundaries, to, from)
      else
        raise "Unsupported IP address assignment: #{allocation_type}"
      end
    end

    def get_assignment_ip(boundaries, from, to)
      if from <= to
        prev = :prev
        follow = :follow
        inequality_sign = :<
        number = :+
      else
        prev = :follow
        follow = :prev
        inequality_sign = :>
        number = :-
      end
      return from if boundaries.empty?
      return from if boundaries[0][prev].nil? && boundaries[0][:ipv4_address] != from

      start_range = nil

      if boundaries[0][follow].nil?
        start_range = boundaries[0][:ipv4_address] if boundaries[0][:ipv4_address] != to
      elsif boundaries.size == 2 && boundaries[1][follow].nil?
        start_range = boundaries[1][:ipv4_address] if boundaries[1][:ipv4_address] != to
      end

      return start_range ? start_range.method(number).call(1) : nil
    end

  end
end
