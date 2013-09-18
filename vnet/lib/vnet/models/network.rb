# -*- coding: utf-8 -*-

module Vnet::Models
  class Network < Base
    taggable 'nw'

    one_to_many :datapath_networks
    one_to_many :dhcp_ranges
    one_to_many :ip_leases
    one_to_many :tunnels
    one_to_many :interfaces

    many_to_many :network_services, :join_table => :interfaces, :right_key => :id, :right_primary_key => :interface_id, :eager_graph => { :interface => { :ip_leases => :ip_address }} do |ds|
      ds.alives
    end

    subset(:alives, {})

    one_to_many :routes, :class=>Route do |ds|
      Route.dataset.join_table(:inner, :interfaces,
                               {:interfaces__network_id => self.id} & {:interfaces__id => :routes__vif_id}
                               ).select_all(:routes).alives
    end

  end
end
