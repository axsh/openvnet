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
      network_md = md_create(:network => @id)
      fo_network_md = flow_options.merge(network_md)

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

      @dp_info.add_flows(flows)
    end

    def update_flows
      local_actions = @interfaces.select { |interface_id, interface|
        interface[:port_number]
      }.collect { |interface_id, interface|
        { :output => interface[:port_number] }
      }

      # Include port LOCAL until we implement interfaces for local eth
      # ports.
      local_actions << { :output => OFPP_LOCAL }

      network_md = md_create(:network => @id)

      flows = []
      flows << Flow.create(TABLE_FLOOD_LOCAL, 1,
                           network_md,
                           local_actions,
                           flow_options.merge(:goto_table => TABLE_FLOOD_ROUTE))

      @dp_info.add_flows(flows)
    end

  end

end
