# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module PortLocal
    include Constants

    def flow_options
      flow_options ||= {:cookie => OFPP_LOCAL | 0x100000000}
    end

    def install
      flows = []

      flows << Flow.create(TABLE_CLASSIFIER,     2, {:in_port => OFPP_LOCAL}, {}, flow_options.merge(:goto_table => TABLE_LOAD_DST))
      flows << Flow.create(TABLE_CLASSIFIER,     3, {:in_port => OFPP_LOCAL, :eth_type => 0x0806}, {}, flow_options.merge(:goto_table => TABLE_ARP_ANTISPOOF))
      flows << Flow.create(TABLE_MAC_ROUTE,      1, {:eth_dst => port_info.hw_addr}, {:output => OFPP_LOCAL}, flow_options)
      flows << Flow.create(TABLE_METADATA_ROUTE, 0, {:metadata => port_info.port_no, :metadata_mask => 0xffffffff}, {:output => port_info.port_no}, flow_options)

      flows << Flow.create(TABLE_LOAD_DST,   1, {:eth_dst => port_info.hw_addr}, {}, flow_options_load_port(TABLE_LOAD_SRC))

      # Some flows depend on only local being able to send packets
      # with the local mac and ip address, so drop those.
      flows << Flow.create(TABLE_LOAD_SRC, 6, {:in_port => OFPP_LOCAL}, {}, flow_options.merge(:goto_table => TABLE_METADATA_ROUTE))
      flows << Flow.create(TABLE_LOAD_SRC, 5, {:eth_src => port_info.hw_addr}, {}, flow_options)
      flows << Flow.create(TABLE_LOAD_SRC, 5, {:eth_type => 0x0800, :ipv4_src => IPAddr.new('192.168.60.101')}, {}, flow_options)

      #
      # ARP routing table
      #
      flows << Flow.create(TABLE_ARP_ANTISPOOF, 1, {:in_port => OFPP_LOCAL, :eth_type => 0x0806}, {}, flow_options.merge(:goto_table => TABLE_ARP_ROUTE))
      flows << Flow.create(TABLE_ARP_ROUTE, 1, {:eth_type => 0x0806, :arp_tpa => IPAddr.new('192.168.60.101')}, {:output => OFPP_LOCAL}, flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
