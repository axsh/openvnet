# -*- coding: utf-8 -*-

module Vnet::Models
  class Route < Base
    taggable 'r'

    many_to_one :iface
    many_to_one :route_link

    subset(:alives, {})

    one_to_many :on_other_networks, :class => Route do |ds|
      ds = Route.join(:ifaces, :routes__iface_id => :ifaces__id)
      ds = ds.where(~{:ifaces__network_id => self.iface.network_id})
      ds.select_all(:routes)
    end

  end
end
