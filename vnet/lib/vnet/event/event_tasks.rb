# -*- coding: utf-8 -*-

module Vnet::Event

  module EventTasks

    def self.included(klass)
      klass.class_eval do
        prepend Initializer
      end
    end

    module Initializer
      def initialize(*args, &block)
        super
        @event_tasks = {}
      end
    end

    # The block should not contain any calls that yield.
    def create_event_task(task_name, max_wait, &block)
      current_task = Celluloid::Task.current
      current_timer = max_wait && after(max_wait) { current_task.resume }

      tasks = (@event_tasks[task_name] ||= {})
      tasks[current_task] = state = { status: :valid }

      while true
        # Suspend returns the value passed to resume by the other
        # task. We do not allow nil to be passed.
        passed_value = Celluloid::Task.suspend(:event_task)
        next if passed_value.nil?

        result = block.call(passed_value)
        break result if result
      end

    ensure
      state[:status] = :invalid

      tasks.delete(current_task)
      current_timer && current_timer.cancel
    end

    def resume_event_tasks(task_name, pass_value)
      (@event_tasks[task_name] || return).dup.each { |task, state|
        next unless state[:status] == :valid

        task.resume(pass_value)
      }
    end

  end

end
