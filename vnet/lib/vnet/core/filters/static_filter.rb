

module Vnet::Core::Filters

  class StaticFilter < Base

    def initialize(params)
      super

      @static_filter
    end

    def log_type
      'filter/static_filter'
    end

    def install
      return if @interface_id.nil?
      flows = []

      @static_filter.each { |id, filter|

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
