# -*- coding: utf-8 -*-

module Vnet::Openflow::Networks

  class Physical < Base

    def network_type
      :physical
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      flood_md = md_create(:flood => nil)

      flows = []
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 30,
                           md_network(:network), nil,
                           flow_options.merge(:goto_table => TABLE_PHYSICAL_SRC))
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 30,
                           md_network(:network), nil,
                           flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))

      @datapath.add_flows(flows)
    end

    def update_flows
      remote_actions = @ports.collect { |port_number, port|
        {:output => port_number}
      }
      local_actions = @ports.select { |port_number, port|
        port[:mode] == :vif || port[:mode] == :local
      }.collect { |port_number, port|
        {:output => port_number}
      }

      flows = []
      flows << Flow.create(TABLE_FLOOD_ROUTE, 1,
                           md_network(:network, :flood => nil),
                           remote_actions,
                           flow_options)
      flows << Flow.create(TABLE_FLOOD_LOCAL, 1,
                           md_network(:network, :flood => nil),
                           local_actions,
                           flow_options)

      @datapath.add_flows(flows)
    end

  end

end
