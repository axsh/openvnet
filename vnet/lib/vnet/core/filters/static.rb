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

      @statics.each { |id, filter|
        
        debug log_format('installing filter')

        flows_for_ingress_filtering(flows, filter) if @ingress_filtering
        flows_for_egress_filtering(flows, filter) if @egress_filtering

      }
      @dp_info.add_flows(flows)
    end


    def added_static_filter
      
    end


    def removed_static_filter

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
      debug log_fomat("@@@@@@@@ creating egress flow with #{filter} @@@@@@@@")
    end

  end

end
