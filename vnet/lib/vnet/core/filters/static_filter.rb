

module Vnet::Core::Filters

  class StaticFilter < Base2

    def initialize(params)
      super

      @static_filters = {}
    end

    def log_type
      'filter/static_filter'
    end

    def install
      return if @interface_id.nil?
      flows = []

      @static_filters.each { |id, filter|
        
        debug log_format(id.to_s)
        debug log_format(filter.to_s)
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
      puts "@@@@@@@@ creating ingress flow with #{filter} @@@@@@@@"
    end

    def flows_for_egress_filtering(flows, filter)
      puts "@@@@@@@@ creating egress flow with #{filter} @@@@@@@@"
    end

  end

end
