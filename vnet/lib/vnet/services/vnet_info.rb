# -*- coding: utf-8 -*-

# Thread-safe access to static information on the services and
# managers.
#
# Since this isn't an actor we avoid the need to go through Datapath's
# thread for every time we use a manager.

module Vnet::Services
  class VnetInfo
    include Vnet::ManagerList

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
      initialize_manager_list(service_managers, timeout, interval)
    end

    def terminate_all_managers(timeout = 10.0)
      terminate_manager_list(service_managers, timeout)
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

  end
end
