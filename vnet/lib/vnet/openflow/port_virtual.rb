# -*- coding: utf-8 -*-

module Vnet::Openflow

  module PortVirtual
    include Vnet::Constants::Openflow

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, {},
                           fo_load_network(TABLE_NETWORK_CLASSIFIER,
                                           METADATA_FLAG_LOCAL,
                                           METADATA_FLAG_LOCAL))

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
      
      flows << Flow.create(TABLE_ROUTER_EXIT, 40,
                           md_network(:network).merge!({ :eth_type => 0x0800,
                                                         :ipv4_dst => @ipv4_addr
                                                       }),
                           { :eth_dst => @hw_addr },
                           flow_options.merge(:goto_table => TABLE_VIRTUAL_DST)
                           ) if @ipv4_addr

      #
      # IPv4 source validation:
      #
      flows << Flow.create(TABLE_VIRTUAL_SRC, 40, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800,
                             :eth_src => @hw_addr,
                             :ipv4_src => @ipv4_addr,
                           }, {}, flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY)
                           ) if @ipv4_addr

      flows << Flow.create(TABLE_VIRTUAL_SRC, 40, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800,
                             :eth_src => @hw_addr,
                             :ipv4_src => IPAddr.new('0.0.0.0'),
                           }, {}, flow_options.merge(:goto_table => TABLE_ROUTER_ENTRY))

      #
      # Destination routing:
      #
      flows << Flow.create(TABLE_VIRTUAL_DST, 60, metadata_n.merge!(:eth_dst => self.hw_addr), {
                             :output => self.port_number
                           }, flow_options)

      flows << Flow.create(TABLE_METADATA_ROUTE, 1, metadata_np, {
                             :output => self.port_number
                           }, flow_options)
      flows << Flow.create(TABLE_METADATA_LOCAL, 1, metadata_np, {
                             :output => self.port_number
                           }, flow_options)

      self.datapath.add_flows(flows)
      self.update_eth_ports
    end

    def update_eth_ports
      flows = []

      self.datapath.switch.eth_ports.each { |port|
        flows << Flow.create(TABLE_HOST_PORTS, 30, {
                               :in_port => port.port_number,
                               :eth_dst => self.hw_addr,
                             }, {}, fo_load_network(TABLE_NETWORK_CLASSIFIER,
                                                    port.port_number,
                                                    METADATA_PORT_MASK))
      }
      self.datapath.add_flows(flows) unless flows.empty?
    end

    def update_tunnel_ports
    end
  end

end
