# -*- coding: utf-8 -*-

module Vnet::Models
  class Network < Base
    class << self
      def attach_iface(uuid, iface_uuid)
        self[uuid].tap do |network|
          network.add_iface(Iface[iface_uuid])
        end
      end

      def detach_iface(uuid, iface_uuid)
        self[uuid].tap do |network|
          network.remove_iface(Iface[iface_uuid])
        end
      end
    end

    taggable 'nw'

    one_to_many :datapath_networks
    one_to_many :dhcp_ranges
    one_to_many :ip_leases
    one_to_many :tunnels
    one_to_many :ifaces

    many_to_many :network_services, :join_table => :ifaces, :right_key => :id, :right_primary_key => :iface_id, :eager_graph => { :iface => { :ip_leases => :ip_address }} do |ds|
      ds.alives
    end

    many_to_one :dc_network

    subset(:alives, {})

    one_to_many :routes, :class=>Route do |ds|
      Route.dataset.join_table(:inner, :ifaces,
                               {:ifaces__network_id => self.id} & {:ifaces__id => :routes__iface_id}
                               ).select_all(:routes).alives
    end

  end
end
