# -*- coding: utf-8 -*-

# Thread-safe access to static information on the services and
# managers.
#
# Since this isn't an actor we avoid the need to go through Datapath's
# thread for every time we use a manager.

module Vnet::Services
  class VnetInfo

    SERVICE_MANAGER_NAMES = %w(
      ip_retention_container
      lease_policy
      topology
    )

    SERVICE_MANAGER_NAMES.each do |name|
      attr_reader "#{name}_manager"
    end

    def initialize
      internal_initialize_managers(SERVICE_MANAGER_NAMES)
    end

    def inspect
      "<##{self.class.name}>"
    end

    #
    # Managers:
    #

    def service_managers
      SERVICE_MANAGER_NAMES.map { |name| __send__("#{name}_manager") }
    end

    def initialize_service_managers(timeout, interval = 10.0)
      service_managers.tap { |manager_list|
        manager_list.each { |manager| manager.event_handler_queue_only }
        manager_list.each { |manager| manager.async.start_initialize }
        internal_wait_for_initialized(manager_list, timeout, interval).tap { |stuck_managers|
          next if stuck_managers.nil?

          stuck_managers.each { |manager|
            Celluloid.logger.warn log_format("#{manager.class.name.to_s.demodulize.underscore} failed to initialize within #{timeout} seconds")
          }
          raise Vnet::ManagerInitializationFailed
        }
        manager_list.each { |manager| manager.event_handler_active }
      }
    end

    def terminate_service_managers(timeout = 10.0)
      internal_terminate_managers(service_managers, timeout)
    end

    #
    # Internal methods:
    #

    private

    def log_format(message, values = nil)
      "#{@dpid_s} dp_info: #{message}" + (values ? " (#{values})" : '')
    end

    def internal_initialize_managers(name_list)
      name_list.each { |name|
        instance_variable_set("@#{name}_manager", Vnet::Services.const_get("#{name.to_s.camelize}Manager").new(self))
      }
    end

    def internal_wait_for_initialized(manager_list, timeout, interval)
      manager_list.dup.tap { |waiting_managers|
        start_timeout = Time.new

        while true
          # Celluloid.logger.debug log_format('internal_wait_for_initialized interval loop')
          start_interval = Time.new

          waiting_managers.delete_if { |manager|
            # Celluloid.logger.debug log_format("internal_wait_for_initialized waiting for #{manager.class.name}")
            manager.wait_for_initialized(interval - (Time.new - start_interval))
          }

          return if waiting_managers.empty?
          return waiting_managers if timeout < (Time.new - start_timeout)
        end
      }
    end

    def internal_terminate_managers(manager_list, timeout)
      manager_list.each { |manager|
        begin
          manager.terminate
        rescue Celluloid::DeadActorError
        end
      }

      start_time = Time.new

      manager_list.each { |manager|
        next_timeout = timeout - (Time.new - start_time)

        Celluloid::Actor.join(manager, (next_timeout < 0.1) ? 0.1 : next_timeout)
      }
    end

  end
end
