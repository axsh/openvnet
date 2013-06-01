# -*- coding: utf-8 -*-

module Vnmgr::Models
  class Datapath < Base
    taggable 'dp'
    many_to_one :open_flow_controller
    
    one_to_many :datapath_networks
    one_to_many :datapaths_on_subnet, :class => Datapath do |ds|
      # Currently returns all datapaths, rather than just the ones
      # that share the same subnet.
      Datapath.dataset.where(~{:datapaths__id => self.id}).alives
    end

    one_to_many :datapath_networks_on_subnet, :class => DatapathNetwork do |ds|
      # Currently returns all datapaths, rather than just the ones
      # that share the same subnet.
      DatapathNetwork.dataset.where(~{:datapath_networks__datapath_id => self.id})
    end

    subset(:alives, {})

  end
end
