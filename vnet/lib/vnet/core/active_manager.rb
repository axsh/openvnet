# -*- coding: utf-8 -*-

module Vnet::Core
  class ActiveManager < Vnet::Core::Manager

    event_handler_default_drop_all

    finalizer :do_cleanup

    #
    # Internal methods:
    #

    def do_initialize
      info log_format('cleaning up old entries')
      
      mw_class.batch.dataset.where(datapath_id: @datapath_info.id).destroy.commit
    end

    private

    # TODO: Add do_initialize, clean up / update old entries.

    # TODO: Fix do_cleanup so it gets called and completed before
    # communication with node_api is shut down.
    def do_cleanup
      # Cleanup might be called before the manager is initialized, in
      # that case do nothing.
      return if @datapath_info.nil?

      info log_format('cleaning up')

      begin
        mw_class.batch.dataset.where(datapath_id: @datapath_info.id).destroy.commit
      rescue NoMethodError => e
        info log_format(e.message, e.class.name)
      end

      info log_format('cleaned up')
    end


  end
end
