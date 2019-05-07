# -*- coding: utf-8 -*-

module Vnet::Core
  class ActiveManager < Vnet::Core::Manager

    #
    # Internal methods:
    #

    def do_initialize
      info log_format('cleaning up old entries')

      mw_class.destroy_where(datapath_id: @datapath_info.id)

      info log_format('loading all entries')

      # TODO: Add an id so we know this instance was then one to call
      # load.
      mw_class.load_where({}, eh__node_id: @datapath_info.node_id)

      info log_format('initialize done')
    end

    private

    # TODO: Fix do_cleanup so it gets called and completed before
    # communication with node_api is shut down.
    def do_cleanup
      # Cleanup might be called before the manager is initialized, in
      # that case do nothing.
      return if @datapath_info.nil?

      info log_format('cleaning up')

      begin
        mw_class.destroy_where(datapath_id: @datapath_info.id)
      rescue NoMethodError => e
        info log_format(e.message, e.class.name)
      end

      info log_format('cleaned up')
    end

  end
end
