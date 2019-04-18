# -*- coding: utf-8 -*-

module Vnet
  module ManagerList

    def initialize_manager_list(manager_list, timeout, interval = 10.0, &block)
      debug log_format("initialize_manager_list event handler queue only")
      manager_list.each { |manager| manager.event_handler_queue_only }

      if block
        debug log_format("initialize_manager_list call block")
        manager_list.each { |manager| block.call(manager) }
      end

      debug log_format("initialize_manager_list start initialize")
      manager_list.each { |manager| manager.async.start_initialize }

      debug log_format("initialize_manager_list wait for initialized")
      internal_wait_for_state(manager_list, timeout, interval, :initialized).tap { |stuck_managers|
        next if stuck_managers.empty?

        stuck_managers.each { |manager|
          Celluloid.logger.warn log_format("#{manager.class.name.to_s.demodulize.underscore} failed to initialize within #{timeout} seconds")
        }
        raise Vnet::ManagerInitializationFailed
      }

      debug log_format("initialize_manager_list event handler activate")
      manager_list.each { |manager| manager.event_handler_active }
    end

    def terminate_manager_list(manager_list, timeout, interval = 10.0)
      debug log_format("terminate_manager_list event handler drop all")
      manager_list.each { |manager| safe_actor_call(manager, :event_handler_drop_all) }

      debug log_format("terminate_manager_list start terminate")
      manager_list.each { |manager| safe_actor_async(manager, :start_terminate) }

      debug log_format("terminate_manager_list wait for terminated")
      internal_wait_for_state(manager_list, timeout, interval, :terminated).tap { |stuck_managers|
        next if stuck_managers.empty?

        stuck_managers.each { |manager|
          Celluloid.logger.warn log_format("#{manager.class.name.to_s.demodulize.underscore} failed to terminate within #{timeout} seconds")

          # TODO: Consider better error handling, and unregister watchdog.
          #raise Vnet::ManagerTerminationFailed
        }
      }

      # debug log_format("terminate_manager_list wait for terminate")
      # manager_list.each { |manager| safe_actor_call(manager, :terminate) }

      debug log_format("terminate_manager_list join actors")

      Time.new.tap { |start_time|
        manager_list.each { |manager|
          next_timeout = timeout - (Time.new - start_time)

          Celluloid::Actor.join(manager, (next_timeout < 0.1) ? 0.1 : next_timeout)
        }
      }
    end

    private

    def safe_actor_call(actor, method_name, *args, &block)
      begin
        actor.send(method_name, *args, &block)
      rescue Celluloid::DeadActorError, Celluloid::Task::TerminatedError
        nil
      end
    end

    def safe_actor_async(actor, method_name, *args, &block)
      begin
        actor.async.send(method_name, *args, &block)
      rescue Celluloid::DeadActorError, Celluloid::Task::TerminatedError
        nil
      end
    end

    def safe_manager_initialized(manager, max_wait)
      begin
        manager.wait_for_initialized(max_wait)
      rescue Celluloid::DeadActorError, Celluloid::Task::TerminatedError
        false
      end
    end

    def safe_manager_terminated(manager, max_wait)
      begin
        return true if manager.wait_for_terminated(max_wait)
        return manager.alive?
      rescue Celluloid::DeadActorError, Celluloid::Task::TerminatedError
        true
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
              safe_manager_initialized(manager, interval - (Time.new - start_interval))
            when :terminated
              safe_manager_terminated(manager, interval - (Time.new - start_interval))
            else
              raise "Invalid state."
            end
          }

          return waiting_managers if waiting_managers.empty?
          return waiting_managers if timeout < (Time.new - start_timeout)
        end
      }
    end

  end    
end
