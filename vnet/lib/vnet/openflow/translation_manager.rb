# -*- coding: utf-8 -*-

module Vnet::Openflow
  class TranslationManager < Manager
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Dispatchable

    def initialize(dp)
      @datapath = dp
      @dpid_s = "0x%016x" % @datapath.dpid

      @edge_ports = []

      info log_format('initialized')
    end

    def add_edge_port(params)
      @edge_ports << params[:port]
      update if params[:update]
    end

    def update
      flows = []

      @translation_map = Vnet::ModelWrappers::VlanTranslation.batch.all.commit

      @edge_ports.each do |port|
        info log_format('create flows for', port.port_name)

        interface = @datapath.interface_manager.item(display_name: port.port_name,
                                                     owner_datapath_id: @datapath.datapath_map.id,
                                                     reinitialize: false)

        flow_options = {:cookie => port.port_number | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT)}

        flows << Flow.create(TABLE_CLASSIFIER, 2, {
                              :in_port => port.port_number
                             }, nil,
                             flow_options.merge(:goto_table => TABLE_VLAN_TRANSLATION))

        # port.mac_addresses.each do |mac|
        #   vlan_ids = get_vlan_ids_by_mac(mac)

        #   if vlan_ids.empty?
        #     flows << Flow.create(TABLE_VIRTUAL_DST, 80, {
        #                                           :eth_dst => Trema::Mac.new(mac)
        #                                          }, {
        #                                           :output => port.port_number
        #                                          }, flow_options)
        #   else
        #     vlan.ids.each do |vlan_id|
        #       flows << Flow.create(TABLE_VIRTUAL_DST, 80, {
        #                                             :eth_dst => Trema::Mac.new(mac)
        #                                            }, {
        #                                             :vlan_vid => vlan_id,
        #                                             :output => port.port_number
        #                                            }, flow_options)
        #     end
        #   end
        # end

        vlan_net = @translation_map.select { |t| t.interface_id == interface.id }

        info log_format('associated vlan_id <-> network_id translation', vlan_net)

        vlan_net.each do |t|
          # strip_tag_flow 1
          ovs_flow = "table=%d,priority=80,cookie=0x%x,dl_vlan=%x," % [TABLE_VLAN_TRANSLATION, flow_options[:cookie], t.vlan_id]

          # send a packet to in_port with vlan tag
          ovs_flow << "actions=learn\\(table=%d,cookie=0x%x,priority=90," % [TABLE_VLAN_TRANSLATION, flow_options[:cookie]]
          ovs_flow << "NXM_OF_ETH_DST\\[\\]=NXM_OF_ETH_SRC\\[\\],load:NXM_OF_VLAN_TCI\\[\\]\\-\\>NXM_OF_VLAN_TCI\\[\\],output:NXM_OF_IN_PORT\\[\\]),"

          # strip_tag_flow 2: match vlan tag then strip tag and write metadata. this flow is the same as strip_tag_flow 1 but without learning flow.
          ovs_flow << "learn\\(table=%d,cookie=0x%x,priority=90," % [TABLE_VLAN_TRANSLATION, flow_options[:cookie]]
          ovs_flow << "strip_vlan,write_metadata:0x%x/0x%x,goto_table:%d)," % [metadata[:metadata], metadata[:metadata_mask], TABLE_ROUTER_CLASSIFIER]

          ovs_flow << "strip_vlan,write_metadata:0x%x/0x%x," % [metadata[:metadata], metadata[:metadata_mask]]
          ovs_flow << "goto_table:%d" % TABLE_ROUTER_CLASSIFIER

          @datapath.add_ovs_flow(ovs_flow)
        end
      end

      @datapath.add_flows(flows)
    end

    private

    def log_format(message, values = nil)
      "#{@dpid_s} translation_manager: #{message}" + (values ? " (#{values})" : '')
    end
  end
end
