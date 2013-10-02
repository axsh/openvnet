# -*- coding: utf-8 -*-

module Vnet::Openflow
  class TranslationManager < Manager
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Dispatchable

    def initialize(dp)
      @datapath = dp
      @edge_ports = []
    end

    def add_edge_port(params)
      @edge_ports << params[:port]
      update if params[:update]
    end

    def update
      flows = []
      ovs_flows = []

      @translation_map = Vnet::ModelWrappers::VlanTranslation.batch.all.commit

      @edge_ports.each do |port|

        flow_options = {:cookie => port.port_number | (COOKIE_PREFIX_PORT << COOKIE_PREFIX_SHIFT)}

        flows << Flow.create(TABLE_CLASSIFIER, 2, {
                              :in_port => port.port_number
                             }, nil,
                             flow_options.merge(:goto_table => TABLE_VLAN_TRANSLATION))

        port.mac_addresses.each do |mac|
          vlan_id = get_vlan_id_from_mac(mac)

          if vlan_id.nil?
            flows << Flow.create(TABLE_VIRTUAL_DST, 80, {
                                                  :eth_dst => Trema::Mac.new(mac)
                                                 }, {
                                                  :output => port.port_number
                                                 }, flow_options)
          else
            flows << Flow.create(TABLE_VIRTUAL_DST, 80, {
                                                  :eth_dst => Trema::Mac.new(mac)
                                                 }, {
                                                  :vlan_vid => vlan_id,
                                                  :output => port.port_number
                                                 }, flow_options)
          end
        end
      end

      @translation_map.each do |t|
        metadata = nil

        if t.network_id
          metadata = md_create(:network => t.network_id)
        else
          raise("no network id found: #{t.inspect}")
        end

        if t.vlan_id.nil?
          if t.mac_address.nil?
            raise("either mac_address of vlan_id is required.")
          else
            flows << Flow.create(TABLE_VLAN_TRANSLATION, 2, {
                                  :eth_src => Trema::Mac.new(t.mac_address)
                                 }, nil, metadata.merge({:goto_table => TABLE_ROUTER_CLASSIFIER}))
          end
        else
          if t.mac_address.nil?
            #ovs_flows << "table=#{TABLE_VLAN_TRANSLATION},priority=2,cookie=0x%x,vlan_vid=%x,actions=learn\\(table=#{TABLE_VIRTUAL_DST},cookie=0x%x,priority=80,NXM_OF_ETH_DST\\[\\]=NXM_OF_ETH_SRC\\[\\],load:NXM_OF_VLAN_TCI\\[\\]\\-\\>NXM_OF_VLAN_TCI\\[\\],output:NXM_OF_IN_PORT\\[\\]),strip_vlan,goto_table:%d"

            # TODO refactor ":strip_vlan => true"
            flows << Flow.create(TABLE_VLAN_TRANSLATION, 2, {
                                  :vlan_vid => t.vlan_id
                                 }, {:strip_vlan => true}, metadata.merge({:goto_table => TABLE_ROUTER_CLASSIFIER}))
          else
            flows << Flow.create(TABLE_VLAN_TRANSLATION, 2, {
                                  :eth_src => Trema::Mac.new(t.mac_address)
                                 }, {:strip_vlan => true}, metadata.merge({:goto_table => TABLE_ROUTER_CLASSIFIER}))
          end
        end

        @datapath.add_flows(flows)
      end
    end

    private

    def get_vlan_id_from_mac(mac)
      translation_map = @translation_map.detect { |t| t.mac_address == mac }

      return nil if translation_map.nil?

      translation_map.vlan_id
    end
  end
end
