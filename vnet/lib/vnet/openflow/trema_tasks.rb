# -*- coding: utf-8 -*-

module Vnet::Openflow

  module TremaTasks

    attr_reader :trema_tasks

    def open_trema_tasks
      @trema_tasks = Trema::Tasks.new
    end

    def close_trema_tasks
      @trema_tasks.close
    end

    def pass_task(&blk)
      @trema_tasks.pass_task(&blk)
    end

  end

end
