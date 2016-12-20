# -*- coding: utf-8 -*-

# Thread-safe access to static information on the services and
# managers.
#
# Since this isn't an actor we avoid the need to go through Datapath's
# thread for every time we use a manager.

module Vnet::Services

  class VnetInfo

    MANAGER_NAMES = %w(
      ip_retention_container
      lease_policy
      topology
    )

    MANAGER_NAMES.each do |name|
      attr_reader "#{name}_manager"
    end

    def initialize
      internal_initialize_managers(MANAGER_NAMES)
    end

    def inspect
      "<##{self.class.name}>"
    end

    #
    # Managers:
    #

    def managers
      MANAGER_NAMES.map { |name| __send__("#{name}_manager") }
    end

    def start_managers(manager_list = managers)
      manager_list.each { |manager| manager.event_handler_queue_only }
      manager_list.each { |manager| manager.async.start_initialize }
      manager_list.each { |manager| manager.wait_for_initialized(nil) }
      manager_list.each { |manager| manager.event_handler_active }
    end


    def terminate_managers(timeout = 10.0)
      internal_terminate_managers(managers, timeout)
    end

    #
    # Internal methods:
    #

    private

    def internal_initialize_managers(name_list)
      name_list.each { |name|
        instance_variable_set("@#{name}_manager", Vnet::Services.const_get("#{name.to_s.camelize}Manager").new(self))
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
