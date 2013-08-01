# -*- coding: utf-8 -*-

module Vnet::Openflow

  module PortVirtual
    include Vnet::Constants::Openflow

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      network_md = flow_options.merge(md_network(:virtual_network))
      classifier_md = flow_options.merge(md_network(:virtual_network, {
                                                      :local => nil,
                                                      :vif => nil
                                                    }))
      
      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, nil,
                           classifier_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))
      flows << Flow.create(TABLE_HOST_PORTS, 30, {
                             :eth_dst => self.hw_addr,
                           }, nil,
                           network_md.merge!(:goto_table => TABLE_NETWORK_CLASSIFIER))

      #
      # ARP Anti-Spoof:
      #
      if @ipv4_addr
        flows << Flow.create(TABLE_VIRTUAL_SRC, 86, {
                               :in_port => self.port_number,
                               :eth_type => 0x0806,
                               :eth_src => @hw_addr,
                               :arp_spa => @ipv4_addr,
                               :arp_sha => @hw_addr
                             }, nil,
                             flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))
      end

      #
      # IPv4 source validation:
      #
      if @ipv4_addr
        flows << Flow.create(TABLE_VIRTUAL_SRC, 40, {
                               :in_port => self.port_number,
                               :eth_type => 0x0800,
                               :eth_src => @hw_addr,
                               :ipv4_src => @ipv4_addr,
                             }, nil,
                             flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))
        flows << Flow.create(TABLE_ROUTER_DST, 40,
                             network_md.merge({ :eth_type => 0x0800,
                                                :ipv4_dst => @ipv4_addr
                                              }), {
                               :eth_dst => @hw_addr
                             },
                             flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))
        flows << Flow.create(TABLE_ARP_LOOKUP, 30,
                             network_md.merge({ :eth_type => 0x0800,
                                                :ipv4_dst => self.ipv4_addr
                                              }), {
                               :eth_dst => self.hw_addr
                             },
                             flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))
      end

      flows << Flow.create(TABLE_VIRTUAL_SRC, 40, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800,
                             :eth_src => @hw_addr,
                             :ipv4_src => IPV4_ZERO,
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))

      #
      # Destination routing:
      #
      flows << Flow.create(TABLE_VIRTUAL_DST, 60,
                           network_md.merge(:eth_dst => self.hw_addr), {
                             :output => self.port_number
                           }, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
