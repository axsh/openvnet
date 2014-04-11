# -*- coding: utf-8 -*-

module Vnet::Models
  class IpRangesRange < Base

    many_to_one :ip_range

    plugin :paranoia

    def_dataset_method(:containing_range) { |begin_range,end_range|
      new_dataset = self
      new_dataset = new_dataset.filter("range_end >= ?", begin_range) if begin_range
      new_dataset = new_dataset.filter("range_begin <= ?", end_range) if end_range
      new_dataset
    }

    def available_ip(from, to, order)
      ipaddr = case order
               when :asc
                 boundaries = IpLease.leased_ip_bound_lease(self.network_id, from, to).limit(2).all
                 ip = get_assignment_ip(boundaries, from, to)
               when :desc
                 boundaries = IpLease.leased_ip_bound_lease(self.network_id, from, to).order(:ip_leases__ipv4.desc).limit(2).all
                 ip = get_assignment_ip(boundaries, to, from)
               else
                 raise "Unsupported IP address assignment: #{network[:ip_assignment]}"
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
      return from if boundaries.size == 0
      return from if boundaries[0][prev].nil? && boundaries[0][:ipv4] != from

      start_range = nil

      if boundaries[0][follow].nil?
        start_range = boundaries[0][:ipv4] if boundaries[0][:ipv4] != to
      elsif boundaries.size == 2 && boundaries[1][follow].nil?
        start_range = boundaries[1][:ipv4] if boundaries[1][:ipv4] != to
      end

      return start_range ? start_range.method(number).call(1) : nil
    end
  end
end
