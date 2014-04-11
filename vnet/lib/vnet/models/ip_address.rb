# -*- coding: utf-8 -*-

module Vnet::Models
  class IpAddress < Base
    include Vnet::ModelWrappers::Helpers::IPv4

    many_to_one :network
    one_to_one :ip_lease
    one_to_one :datapath

    def_dataset_method(:leased_ip_bound_lease) { |network_id, from, to|
      filter_join_main = {:ip_leases__ipv4=>from..to} & {:ip_leases__network_id=>network_id}
      filter_join_prev = {:prev__ipv4=>from..to} & {:prev__network_id=>network_id} & {:ip_leases__ipv4=>:prev__ipv4 + 1}
      filter_join_follow = {:follow__ipv4=>from..to} & {:follow__network_id=>network_id} & {:ip_leases__ipv4=>:follow__ipv4 - 1}

      select_statement = IpLease.select(:ip_leases__ipv4, :prev__ipv4___prev, :follow__ipv4___follow).filter(filter_join_main)
      select_statement = select_statement.join_table(:left, :ip_leases___prev, filter_join_prev)
      select_statement = select_statement.join_table(:left, :ip_leases___follow, filter_join_follow)
      select_statement.filter({:prev__ipv4=>nil} | {:follow__ipv4=>nil})
    }
  end
end
