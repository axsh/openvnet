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

    def install
      return if @interface_id.nil?
      flows = []
      flows_for_passthrough(flows)

      @statics.each { |id, filter|
        
        debug log_format('installing static')

        flows_for_ingress_filtering(flows, filter) # if @ingress_filtering
        flows_for_egress_filtering(flows, filter)  # if @egress_filtering

      }
      # @dp_info.add_flows(flows)
    end


    def added_static(static_id, ipv4_address, port_number)
      filter = {
        :static_id => static_id,
        :ipv4_address => ipv4_address,
        :port_number => port_number
      }
      @statics[static_id] = filter

#      debug log_format( statics.to_s)
      return if @installed == false
               
        flows_for_ingress_filtering(flows,filter)  #if  @ingress_filtering
        flows_for_egress_filtering(flows, filter)  # if @egress_filtering

    end


    def removed_static(static_id)
    end

    #
    # Internal methods
    #

    private

    def match_actions(filter)

    end

    def flows_for_ingress_filtering(flows, filter)
      debug log_format("@@@@@@@@ creating ingress flow with #{filter} @@@@@@@@")
    end

    def flows_for_egress_filtering(flows, filter)
      debug log_format("@@@@@@@@ creating egress flow with #{filter} @@@@@@@@")
    end

    def flows_for_passthrough(flow)
      debug log_format("@@@@@@@@ creating passthrough flow with passthrough = #{@passthrough} @@@@@@@@")
    end

    
  end

end
