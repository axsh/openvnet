# -*- coding: utf-8 -*-

module Vnet::Models
  class Route < Base
    taggable 'r'

    many_to_one :interface
    many_to_one :route_link

    subset(:alives, {})

    one_to_many :on_other_networks, :class => Route do |ds|
      ds = Route.join(:interfaces, :routes__vif_id => :interfaces__id)
      ds = ds.where(~{:interfaces__network_id => self.vif.network_id})
      ds.select_all(:routes)
    end

  end
end
