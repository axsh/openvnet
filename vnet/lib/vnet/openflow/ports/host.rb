# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Host
    include Vnet::Openflow::FlowHelpers

    attr_accessor :interface_id

    def port_type
      :host
    end

    def flow_options
      @flow_options ||= {:cookie => @cookie}
    end

    def install
      set_remote_md = flow_options.merge(md_create(:remote => nil))

      reflection_md = md_create(:reflection => nil)
      reflection_mac2mac_md = md_create({ :reflection => nil,
                                          :mac2mac => nil
                                        })

      goto_table_on_table_classifier = @dp_info.datapath.datapath_map.node_id == 'edge' ? TABLE_EDGE_SRC : TABLE_HOST_PORTS

      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, nil,
                           set_remote_md.merge(:goto_table => goto_table_on_table_classifier))
      flows << Flow.create(TABLE_VIRTUAL_SRC, 30, {
                             :in_port => self.port_number
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTE_INGRESS))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 41, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTE_INGRESS))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 41, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTE_INGRESS))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 31, {
                             :in_port => self.port_number
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTE_INGRESS))

      flows << Flow.create(TABLE_PHYSICAL_DST, 21,
                           reflection_md.merge(:in_port => self.port_number), {
                             :output => OFPP_IN_PORT
                           },
                           flow_options)
      flows << Flow.create(TABLE_PHYSICAL_DST, 20, {
                           }, {
                             :output => self.port_number
                           },
                           flow_options)

      # For now set the latest eth port as the default MAC2MAC output
      # port.
      flows << Flow.create(TABLE_OUTPUT_MAC2MAC, 2,
                           reflection_mac2mac_md.merge(:in_port => self.port_number), {
                             :output => OFPP_IN_PORT
                           },
                           flow_options)
      flows << Flow.create(TABLE_OUTPUT_MAC2MAC, 1,
                           md_create(:mac2mac => nil), {
                             :output => self.port_number
                           },
                           flow_options)

      # Currently only support a single host port at this moment.
      #
      # TODO: Fix this....
      flows << Flow.create(TABLE_FLOOD_ROUTE, 1,
                           {},
                           [{ :output => OFPP_LOCAL },
                            { :output => self.port_number }],
                           flow_options)

      @dp_info.add_flows(flows)
      @dp_info.dc_segment_manager.async.update(event: :insert_port_number,
                                               port_number: self.port_number)
    end

    def uninstall
      @dp_info.dc_segment_manager.async.update(event: :remove_port_number,
                                               port_number: self.port_number)
    end

  end

end
