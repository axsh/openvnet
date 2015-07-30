# -*- coding: utf-8 -*-

module Vnet::Core::Filters

  class Static < Base2

    def initialize(params)
      super
      
      @statics = {}
    end

    def log_type
      'filter/static'
    end

    def pretty_static(sf)
      "fil_id:#{sf[:static_id]} ipv4_address:#{sf[:ipv4_address]} port_number:#{sf[:port_number]}"
    end
    
    def install

      return if @interface_id.nil?
      flows = []
      flows_for_passthrough(flows)
      
      @statics.each { |id, filter|
        
        debug log_format('installing translation for ' + pretty_static(filter))

        flows_for_ingress_filtering(flows, filter) #if @ingress_filtering
        flows_for_egress_filtering(flows, filter)  #if @egress_filtering
      }

      @dp_info.add_flows(flows)

    end


    def added_static(static_id, ipv4_address, port_number)

      filter = {
        :static_id => static_id,
        :ipv4_address => ipv4_address,
        :port_number => port_number
      }
      
      @statics[static_id] = filter

      return if @installed == false

      flows = []         
      flows_for_ingress_filtering(flows,filter) #if @ingress_filtering
      flows_for_egress_filtering(flows, filter) #if @egress_filtering

    end


    def removed_static(static_id)
    end

    #
    # Internal methods
    #

    private

    def match_actions(filter)
      port_number = filter[:port_number]

      if port_number
        [{ eth_type: ETH_TYPE_IPV4,
          ipv4_dst: filter[:ipv4_address],
          ip_proto: IPV4_PROTOCOL_TCP,
          tcp_dst: port_number
          },
         { eth_type: ETH_TYPE_IPV4,
           ipv4_dst: filter[:ipv4_address],
           ip_proto: IPV4_PROTOCOL_UDP,
           udp_dst: port_number
          }]
      else
        [{ eth_type: ETH_TYPE_IPV4,
          ipv4_dst: filter[:ipv4_address]
          }]
      end
    end

    def flows_for_ingress_filtering(flows, filter)

      match_actions(filter).each { |match|

        flow_options = {
          table: TABLE_INTERFACE_INGRESS_FILTER,
          goto_table: TABLE_OUT_PORT_INTERFACE_INGRESS,
          priority: 50,
          match: match,
          match_interface: @interface_id
        }
        flows << flow_create(flow_options)
      }
    end

    def flows_for_egress_filtering(flows, filter)

      match_actions(filter).each { |match|

        flow_options = {
          table: TABLE_INTERFACE_EGRESS_FILTER,
          goto_table: TABLE_OUT_PORT_INTERFACE_EGRESS,
          priority: 50,
          match: match,
          match_interface: @interface_id
        }
        flows << flow_create(flow_options)
      }
    end

    def flows_for_passthrough(flows)

      [[TABLE_INTERFACE_INGRESS_FILTER, TABLE_OUT_PORT_INTERFACE_INGRESS],
       [TABLE_INTERFACE_EGRESS_FILTER, TABLE_OUT_PORT_INTERFACE_EGRESS]
      ].each { |table, goto_table|
        flows << flow_create(table: table,
                             goto_table: goto_table,
                             priority: 10,
                             
                             match_interface: @interface_id
                            )
      }
     end

    
  end

end
