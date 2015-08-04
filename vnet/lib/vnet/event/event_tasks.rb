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

    def has_event_task_id?(task_name, task_id)
      tasks = @event_tasks[task_name] || return
      tasks.any? { |task, state|
        state[:status] == :valid && state[:id] == task_id
      }
    end

    # The block and task_init should not contain any calls that yield,
    # this includes async.
    #
    # If task_init returns a non-nil value, it means that during the
    # init proc call the event condition was satisfied.
    def create_event_task(task_name, max_wait, task_id = nil, task_init = nil, &block)
      current_task = Celluloid::Task.current

      state = {
        status: :init,
        id: task_id
      }

      tasks = (@event_tasks[task_name] ||= {})
      tasks[current_task] = state

      # The task_init call should always return the same object as we
      # would receive from the block call, or nil if we should just
      # wait.
      result = task_init && task_init.call
      return result if result

      # We make sure that if timer was made invalid during the task
      # init we return nil.
      return if state[:status] != :init
      state[:status] = :valid

      current_timer = max_wait && after(max_wait) {
        old_state = state[:status]
        state[:status] = :invalid
        current_task.resume if old_state == :valid
      }

      while state[:status] == :valid
        # Suspend returns the value passed to resume by the other
        # task. We do not allow nil to be passed.
        passed_value = Celluloid::Task.suspend(:event_task)

        break if state[:status] == :invalid
        next if passed_value.nil?

        result = block.call(passed_value)
        return result if result
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
