# -*- coding: utf-8 -*-

module Vnet
  class Manager
    module Watchdog
      def self.included(klass)
        klass.include(InstanceMethods)
      end

      module InstanceMethods

        def watchdog_check(event_task_timeout = 10)
          return {
            id: @watchdog_id,
            event_task_count: @event_tasks && @event_tasks.size,
            event_task_stuck: watchdog_stuck_event_tasks(event_task_timeout),
          }
        end

        private

        def init_watchdog(wid)
          @watchdog_id = wid
          @watchdog_registered = nil
        end

        def watchdog_register
          debug log_format_h('registering watchdog', id: @watchdog_id)

          watchdog = Celluloid::Actor[:service_watchdog]

          raise "Actor is already registered with watchdog." if @watchdog_register
          raise "Watchdog is not registered in Celluloid::Actor." if watchdog.nil?

          a = Thread.current[:celluloid_actor]

          # watchdog.register_actor(@watchdog_id, Thread.current[:celluloid_actor].proxy)
          @watchdog_registered = watchdog.register_actor(@watchdog_id, Celluloid::CellProxy.new(a.proxy, a.mailbox, @watchdog_id))

        rescue Celluloid::DeadActorError
          raise "Watchdog is dead."
        end

        def watchdog_unregister
          if @watchdog_register.nil?
            debug log_format('can not unregister watchdog, not registered')
            return
          end

          debug log_format_h('unregistering watchdog', id: @watchdog_id)

          watchdog.unregister_actor(@watchdog_id, @watchdog_registered)
        end

        def watchdog_stuck_event_tasks(event_task_timeout)
          results = []
          return results if @event_tasks.nil?

          timeout_at = Time.now.to_i - event_task_timeout

          @event_tasks.each { |task_name, tasks|
            tasks.select { |task, state|
              state[:created_at] <= timeout_at
            }.each { |task, state|
              results << {task_name: task_name, chain_id: task.chain_id}.merge(state)
            }
          }

          return results
        end

      end
    end
  end
end
