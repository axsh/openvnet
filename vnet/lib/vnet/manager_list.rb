# -*- coding: utf-8 -*-

module Vnet
  module ManagerList

    def initialize_manager_list(manager_list, timeout, interval = 10.0, &block)
      manager_list.each { |manager| manager.event_handler_queue_only }
      block && manager_list.each { |manager| block.call(manager) }
      manager_list.each { |manager| manager.async.start_initialize }

      internal_wait_for_state(manager_list, timeout, interval, :initialized).tap { |stuck_managers|
        next if stuck_managers.nil?

        stuck_managers.each { |manager|
          Celluloid.logger.warn log_format("#{manager.class.name.to_s.demodulize.underscore} failed to initialize within #{timeout} seconds")
        }
        raise Vnet::ManagerInitializationFailed
      }
      manager_list.each { |manager| manager.event_handler_active }
    end

    def terminate_manager_list(manager_list, timeout)
      manager_list.each { |manager| safe_actor_call(manager, :event_handler_drop_all) }
      manager_list.each { |manager|
        safe_actor_call(manager) { |manager|
          manager.async.start_cleanup
        }
      }

      internal_wait_for_state(manager_list, timeout, interval, :terminated).tap { |stuck_managers|
        next if stuck_managers.nil?

        stuck_managers.each { |manager|
          Celluloid.logger.warn log_format("#{manager.class.name.to_s.demodulize.underscore} failed to terminate within #{timeout} seconds")

          # TODO: Consider better error handling, and unregister watchdog.
          raise Vnet::ManagerTerminationFailed
        }
      }

      manager_list.each { |manager| safe_actor_call(manager, :terminate) }

      start_time = Time.new

      manager_list.each { |manager|
        next_timeout = timeout - (Time.new - start_time)

        Celluloid::Actor.join(manager, (next_timeout < 0.1) ? 0.1 : next_timeout)
      }
    end

    private

    def safe_actor_call(actor, method_name, *args, &block)
      begin
        actor.send(method_name, *args, &block)
      rescue Celluloid::DeadActorError
        nil
      end
    end

    def internal_wait_for_state(manager_list, timeout, interval, state)
      manager_list.dup.tap { |waiting_managers|
        start_timeout = Time.new

        while true
          # Celluloid.logger.debug log_format('internal_wait_for_initialized interval loop')
          start_interval = Time.new

          waiting_managers.delete_if { |manager|
            # Celluloid.logger.debug log_format("internal_wait_for_initialized waiting for #{manager.class.name}")

            case state
            when :initialized
              manager.wait_for_initialized(interval - (Time.new - start_interval))
            when :terminated
              safe_actor_call(manager) { |manager|
                manager.wait_for_terminated(interval - (Time.new - start_interval))
              }
            else
              raise "Invalid state."
            end
          }

          return if waiting_managers.empty?
          return waiting_managers if timeout < (Time.new - start_timeout)
        end
      }
    end

  end    
end
