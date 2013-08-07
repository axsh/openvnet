# -*- coding: utf-8 -*-

module Vnet::Openflow::Ports

  module Host
    include Vnet::Openflow::FlowHelpers

    def eth?
      true
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

      flows = []
      flows << Flow.create(TABLE_CLASSIFIER, 2, {
                             :in_port => self.port_number
                           }, nil,
                           set_remote_md.merge(:goto_table => TABLE_HOST_PORTS))

      if @network_id
        fo_network_md = flow_options.merge(md_network(:physical_network))
        flows << Flow.create(TABLE_HOST_PORTS, 10, {
                               :in_port => self.port_number
                             }, nil,
                             fo_network_md.merge(:goto_table => TABLE_NETWORK_CLASSIFIER))
      end

      flows << Flow.create(TABLE_VIRTUAL_SRC, 30, {
                             :in_port => self.port_number
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_CLASSIFIER))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 41, {
                             :in_port => self.port_number,
                             :eth_type => 0x0800
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_CLASSIFIER))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 41, {
                             :in_port => self.port_number,
                             :eth_type => 0x0806
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_CLASSIFIER))
      flows << Flow.create(TABLE_PHYSICAL_SRC, 31, {
                             :in_port => self.port_number
                           }, nil,
                           flow_options.merge(:goto_table => TABLE_ROUTER_CLASSIFIER))

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
      flows << Flow.create(TABLE_OUTPUT_DATAPATH, 2,
                           reflection_mac2mac_md.merge(:in_port => self.port_number), {
                             :output => OFPP_IN_PORT
                           },
                           flow_options)
      flows << Flow.create(TABLE_OUTPUT_DATAPATH, 1,
                           md_create(:mac2mac => nil), {
                             :output => self.port_number
                           },
                           flow_options)

      self.datapath.add_flows(flows)
      self.datapath.network_manager.update_all_flows
    end

  end

end
