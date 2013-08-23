# -*- coding: utf-8 -*-

module Vnet::Openflow

  class NetworkPhysical < Network

    def network_type
      :physical
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flood_md = md_create(:flood => nil)

      flows = []

      flows << Flow.create(TABLE_NETWORK_CLASSIFIER, 30,
                           md_network(:physical_network), nil,
                           flow_options.merge(:goto_table => TABLE_PHYSICAL_SRC))
      flows << Flow.create(TABLE_PHYSICAL_DST, 30,
                           md_network(:network, :remote => nil).merge(:eth_dst => MAC_BROADCAST),
                           nil,
                           flow_options.merge(flood_md).merge(:goto_table => TABLE_METADATA_LOCAL))
      flows << Flow.create(TABLE_PHYSICAL_DST, 30,
                           md_network(:network, :local => nil).merge(:eth_dst => MAC_BROADCAST),
                           nil,
                           flow_options.merge(flood_md).merge(:goto_table => TABLE_METADATA_ROUTE))

      self.datapath.add_flows(flows)
    end

    def update_flows
      remote_actions = @ports.collect { |key,port|
        {:output => port.port_number}
      }
      local_actions = @ports.select { |key, port|
        !port.eth?
      }.collect { |key, port|
        {:output => port.port_number}
      }

      flows = []
      flows << Flow.create(TABLE_METADATA_ROUTE, 1,
                           md_network(:network, :flood => nil),
                           remote_actions,
                           flow_options)
      flows << Flow.create(TABLE_METADATA_LOCAL, 1,
                           md_network(:network, :flood => nil),
                           local_actions,
                           flow_options)

      self.datapath.add_flows(flows)
    end

  end

end
