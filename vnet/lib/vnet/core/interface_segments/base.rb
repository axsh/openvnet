# -*- coding: utf-8 -*-

module Vnet::Core::InterfaceSegments

  class Base < Vnet::ItemDpId
    include Celluloid::Logger
    include Vnet::Openflow::FlowHelpers

    attr_reader :interface_id
    attr_reader :segment_id
    attr_accessor :static

    def initialize(params)
      super

      map = params[:map]

      @interface_id = get_param_id(map, :interface_id)
      @segment_id = get_param_id(map, :segment_id)
      @static = get_param_bool(map, :static)
    end

    def mode
      :base
    end

    def log_type
      'interface_segment/base'
    end

    def pretty_id
      "#{mode}/#{id}"
    end

    def pretty_properties
      "interface_id:#{@interface_id} segment_id:#{@segment_id}" + (@static ? ' static' : '')
    end

    def cookie
      id | COOKIE_TYPE_INTERFACE_SEGMENT
    end

    def install
      flows = []
      flows_for_base(flows)
      flows_for_arp_learning(flows)

      @dp_info.add_flows(flows)
      @dp_info.segment_manager.insert_interface_segment(@interface_id, @segment_id)
    end

    def uninstall
      @dp_info.segment_manager.remove_interface_segment(@interface_id, @segment_id)
    end

    def to_hash
      Vnet::Core::InterfaceSegment.new(
        id: @id,
        interface_id: @interface_id,
        segment_id: @segment_id,
        static: @static
      )
    end

    #
    # Internal methods:
    #

    private

    def flows_for_base(flows)
      flows << flow_create(table: TABLE_PROMISCUOUS_PORT,
                           goto_table: TABLE_SEGMENT_SRC_CLASSIFIER,
                           priority: 10,
                           match_interface: @interface_id,
                           write_segment: @segment_id)
    end

    def flows_for_arp_learning(flows)
      prom_port_number = get_prom_port_number || return
      host_interface_id = get_host_interface_id || return

      match_md = md_create(interface: @interface_id)
      learn_md = md_create(interface: host_interface_id, remote: nil)
      write_md = md_create(segment: @segment_id)

      flow_learn_arp = "table=#{TABLE_PROMISCUOUS_PORT},priority=20,cookie=0x%x,arp,metadata=0x%x/0x%x,actions=" %
        [cookie, match_md[:metadata], match_md[:metadata_mask]]
      flow_learn_arp << "load:#{prom_port_number}->NXM_NX_REG1[],"
      flow_learn_arp << "learn(table=%d,cookie=0x%x,idle_timeout=36000,priority=29,metadata:0x%x,NXM_OF_ETH_DST[]=NXM_OF_ETH_SRC[]," %
        [TABLE_INTERFACE_INGRESS_MAC, cookie, learn_md[:metadata]]
      flow_learn_arp << "output:NXM_NX_REG1[]),"
      flow_learn_arp << "write_metadata=0x%x/0x%x,goto_table:%d" % 
        [write_md[:metadata], write_md[:metadata_mask], TABLE_SEGMENT_SRC_CLASSIFIER]

      debug log_format("flows_for_arp_learning", flow_learn_arp)

      @dp_info.add_ovs_flow(flow_learn_arp)
    end

    # Ugly but simple way of getting a host interface.
    def get_host_interface_id
      # debug log_format_h("get_active_interface filter", filter)

      filter = {
        datapath_id: @dp_info.interface_segment_manager.datapath_info.id,
        segment_id: @segment_id
      }

      dp_seg = MW::DatapathSegment.batch.dataset.where(filter).first.commit
      debug log_format("get_host_interface datapath_segment", dp_seg.inspect)

      dp_seg && dp_seg.interface_id
    end

    def get_prom_port_number
      active_interface = MW::ActiveInterface.batch.dataset.where(interface_id: @interface_id).first.commit

      if active_interface.nil?
        # debug log_format("get_prom_interface active_interface for #{@interface_id}", failed: 'no active_interface')
        return
      end

      active_interface.batch.interface.commit.tap { |interface|
        if interface.nil? || interface.mode != Vnet::Constants::Interface::MODE_PROMISCUOUS
          # debug log_format("get_prom_interface active_interface for #{@interface_id}",
          #                  failed: 'not promiscuous mode', interface: interface)
          return
        end
      }

      debug log_format("get_prom_interface active_interface for #{@interface_id}", active_interface.inspect)

      active_interface && active_interface.port_number
    end

  end

end
