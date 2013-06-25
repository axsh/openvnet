# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortGre
    include Constants

    def flow_options
      @flow_options ||= {:cookie => self.port_number | (self.network_number << COOKIE_NETWORK_SHIFT)}
    end

    def gre?
      true
    end

    def install
      flows = []

      flows << Flow.create(TABLE_CLASSIFIER, 3, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806
                           }, {}, flow_options.merge(:goto_table => TABLE_ARP_ANTISPOOF))

      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, {}, flow_options.merge(:goto_table => TABLE_VIRTUAL_SRC))

      self.datapath.add_flows(flows)
      self.datapath.switch.network_manager.update_all_flows 
    end
  end
end
