# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor.
  class IpAddress < Base
    include Vnet::ModelWrappers::Helpers::IPv4

    plugin :paranoia

    many_to_one :network
    one_to_one :ip_lease
    one_to_one :datapath

    def_dataset_method(:leased_ip_bound_lease) { |network_id, from, to|
      filter_join_main = {:ip_addresses__ipv4_address=>from..to} & {:ip_addresses__network_id=>network_id}
      filter_join_prev = {:prev__ipv4_address=>from..to} & {:prev__network_id=>network_id} & {:ip_addresses__ipv4_address=>:prev__ipv4_address + 1}
      filter_join_follow = {:follow__ipv4_address=>from..to} & {:follow__network_id=>network_id} & {:ip_addresses__ipv4_address=>:follow__ipv4_address - 1}

      select_statement = IpAddress.select(:ip_addresses__ipv4_address, :prev__ipv4_address___prev, :follow__ipv4_address___follow).filter(filter_join_main)
      select_statement = select_statement.join_table(:left, :ip_addresses___prev, filter_join_prev)
      select_statement = select_statement.join_table(:left, :ip_addresses___follow, filter_join_follow)
      select_statement.filter({:prev__ipv4_address=>nil} | {:follow__ipv4_address=>nil})
    }
  end
end
