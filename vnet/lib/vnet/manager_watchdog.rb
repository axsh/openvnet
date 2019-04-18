# -*- coding: utf-8 -*-

module Vnet
  class Manager
    module Watchdog
      def self.included(klass)
        klass.include(InstanceMethods)
      end

      module InstanceMethods

        def watchdog_check
          return {
            id: @watchdog_id,
            event_task_count: @event_tasks && @event_tasks.size,
          }
        end

        private

        def init_watchdog(wid)
          @watchdog_id = wid
          @watchdog_registered = nil
        end

        def watchdog_actor
          watchdog = Celluloid::Actor[:service_watchdog]
          raise "Actor is already registered with watchdog." if @watchdog_register
          raise "Watchdog is not registered in Celluloid::Actor." if watchdog == nil

          watchdog
        end

        def watchdog_register
          debug log_format_h('registering watchdog', id: @watchdog_id)

          a = Thread.current[:celluloid_actor]

          @watchdog_registered = watchdog_actor.register_actor(@watchdog_id, Celluloid::CellProxy.new(a.proxy, a.mailbox, @watchdog_id))

        rescue Celluloid::DeadActorError
          raise "Watchdog is dead."
        end

        def watchdog_unregister
          if @watchdog_registered == nil
            debug log_format('can not unregister watchdog, not registered')
            return
          end

          debug log_format_h('unregistering watchdog', id: @watchdog_id)

          watchdog_actor.unregister_actor(@watchdog_id, @watchdog_registered)
        end

      end
    end
  end
end
