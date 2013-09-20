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
      network_md = md_network(:network)
      fo_network_md = flow_options.merge(md_network(:network))

      flows = []
      flows << Flow.create(TABLE_HOST_PORTS, 10,
                           {}, nil,
                           fo_network_md.merge(:goto_table => TABLE_NETWORK_SRC_CLASSIFIER))
      flows << Flow.create(TABLE_LOCAL_PORT, 10,
                           {}, nil,
                           fo_network_md.merge(:goto_table => TABLE_NETWORK_SRC_CLASSIFIER))
      flows << Flow.create(TABLE_NETWORK_SRC_CLASSIFIER, 30,
                           network_md, nil,
                           flow_options.merge(:goto_table => TABLE_PHYSICAL_SRC))
      flows << Flow.create(TABLE_NETWORK_DST_CLASSIFIER, 30,
                           network_md, nil,
                           flow_options.merge(:goto_table => TABLE_PHYSICAL_DST))

      @datapath.add_flows(flows)
    end

    def update_flows
      local_actions = @ports.select { |port_number, port|
        port[:mode] == :vif || port[:mode] == :local
      }.collect { |port_number, port|
        {:output => port_number}
      }
      remote_actions = @ports.select { |port_number, port|
        port[:mode] == :eth
      }.collect { |port_number, port|
        {:output => port_number}
      }

      flows = []
      flows << Flow.create(TABLE_FLOOD_LOCAL, 1,
                           md_network(:network),
                           local_actions,
                           flow_options.merge(:goto_table => TABLE_FLOOD_ROUTE))
      flows << Flow.create(TABLE_FLOOD_ROUTE, 1,
                           md_network(:network),
                           remote_actions,
                           flow_options)

      @datapath.add_flows(flows)
    end

  end

end
