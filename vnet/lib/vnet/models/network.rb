# -*- coding: utf-8 -*-

module Vnet::Models
  class Network < Base
    class << self
      def attach_interface(uuid, interface_uuid)
        self[uuid].tap do |network|
          network.add_interface(Interface[interface_uuid])
        end
      end

      def detach_interface(uuid, interface_uuid)
        self[uuid].tap do |network|
          network.remove_interface(Interface[interface_uuid])
        end
      end
    end

    taggable 'nw'

    one_to_many :datapath_networks
    one_to_many :dhcp_ranges
    one_to_many :ip_leases
    one_to_many :tunnels
    one_to_many :interfaces

    many_to_many :network_services, :join_table => :interfaces, :right_key => :id, :right_primary_key => :interface_id, :eager_graph => { :interface => { :ip_leases => :ip_address }} do |ds|
      ds.alives
    end

    many_to_one :dc_network

    subset(:alives, {})

    one_to_many :routes, :class=>Route do |ds|
      Route.dataset.join_table(:inner, :interfaces,
                               {:interfaces__network_id => self.id} & {:interfaces__id => :routes__interface_id}
                               ).select_all(:routes).alives
    end

  end
end
