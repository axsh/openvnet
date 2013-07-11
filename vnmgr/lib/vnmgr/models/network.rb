# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Network < Base
    class << self
      def attach_vif(uuid, vif_uuid)
        self[uuid].tap do |network|
          network.add_vif(Vif[vif_uuid])
        end
      end

      def detach_vif(uuid, vif_uuid)
        self[uuid].tap do |network|
          network.remove_vif(Vif[vif_uuid])
        end
      end
    end

    taggable 'nw'

    one_to_many :datapath_networks
    one_to_many :dhcp_ranges
    one_to_many :ip_leases
    one_to_many :tunnels
    one_to_many :vifs

    many_to_many :network_services, :join_table => :vifs, :right_key => :id, :right_primary_key => :vif_id, :eager_graph => { :vif => { :ip_leases => :ip_address }} do |ds|
      ds.alives
    end

    many_to_one :dc_network

    subset(:alives, {})

    one_to_many :routes, :class=>Route do |ds|
      Route.dataset.join_table(:inner, :vifs,
                               {:vifs__network_id => self.id} & {:vifs__id => :routes__vif_id}
                               ).select_all(:routes).alives
    end

  end
end
