# -*- coding: utf-8 -*-

module Vnet::Core::ActivePorts

  class Local < Base

    def mode
      :local
    end

    def log_type
      'active_port/local'
    end

    class << self
      include Vnet::Openflow::FlowHelpers

      # TODO: Make this flow default for the switch.
      def add_flows_for_id(dp_info, item_id)
        # flows = []
        # flows << flow_create(table: TABLE_CLASSIFIER,
        #                      goto_table: TABLE_LOCAL_PORT,
        #                      priority: 2,
        #                      match: {
        #                        :in_port => OFPP_LOCAL
        #                      },
        #                      write_local: true,
        #                      cookie: cookie_for_id(item_id))

        # dp_info.add_flows(flows)
      end

    end
  end

end
