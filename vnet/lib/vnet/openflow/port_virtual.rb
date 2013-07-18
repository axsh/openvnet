# -*- coding: utf-8 -*-

module Vnet::Openflow

  module PortVirtual
    include Vnet::Constants::Openflow

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      any_network_md = flow_options.merge(md_network(:virtual_network))
      local_network_md = flow_options.merge(md_network(:virtual_network, :local => nil))
      
      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, {},
                           local_network_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))
      flows << Flow.create(TABLE_HOST_PORTS, 30, {
                             :eth_dst => self.hw_addr,
                           }, {},
                           any_network_md.merge!(:goto_table => TABLE_NETWORK_CLASSIFIER))

      #
      # ARP Anti-Spoof:
      #
      flows << Flow.create(TABLE_VIRTUAL_SRC, 86, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806,
                             :eth_src => @hw_addr,
                             :arp_spa => @ipv4_addr,
                             :arp_sha => @hw_addr
                           }, {}, flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY)
                           ) if @ipv4_addr
      
      if @ipv4_addr
        flows << Flow.create(TABLE_ROUTER_EXIT, 40,
                             md_network(:virtual_network).merge!({ :eth_type => 0x0800,
                                                                   :ipv4_dst => @ipv4_addr
                                                                 }),
                             { :eth_dst => @hw_addr },
                             flow_options.merge(:goto_table => TABLE_VIRTUAL_DST))
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
                             }, {}, flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))
      end

      flows << Flow.create(TABLE_VIRTUAL_SRC, 40, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800,
                             :eth_src => @hw_addr,
                             :ipv4_src => IPAddr.new('0.0.0.0'),
                           }, {}, flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))

      #
      # Destination routing:
      #
      flows << Flow.create(TABLE_VIRTUAL_DST, 60,
                           md_network(:virtual_network).merge!(:eth_dst => self.hw_addr), {
                             :output => self.port_number
                           }, flow_options)

      # route_md = md_network(:virtual_network, :port => self.port_number)

      # flows << Flow.create(TABLE_METADATA_ROUTE, 1, route_md, {
      #                        :output => self.port_number
      #                      }, flow_options)
      # flows << Flow.create(TABLE_METADATA_LOCAL, 1, route_md, {
      #                        :output => self.port_number
      #                      }, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
