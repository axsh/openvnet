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
    one_to_many :routers
    one_to_many :tunnels
    one_to_many :vifs

    many_to_one :dc_network

    subset(:alives, {})

  end
end
