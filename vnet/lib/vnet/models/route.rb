# -*- coding: utf-8 -*-

module Vnet::Models
  class Route < Base
    taggable 'r'

    many_to_one :vif
    many_to_one :route_link

    subset(:alives, {})

    one_to_many :on_other_networks, :class => Route do |ds|
      ds = Route.join(:vifs, :routes__vif_id => :vifs__id)
      ds = ds.where(~{:vifs__network_id => self.vif.network_id})
      ds.select_all(:routes)
    end

  end
end
