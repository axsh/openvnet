module Vnet::Services
  class VnetInfo
    MANAGER_NAMES = %w(
      ip_retention
    )

    MANAGER_NAMES.each do |name|
      attr_reader "#{name}_manager"
    end

    def managers
      MANAGER_NAMES.map { |name| __send__("#{name}_manager") }
    end

    def initialize_managers
      MANAGER_NAMES.map do |name|
        Vnet::Services.const_get("#{name.to_s.camelize}Manager").new(self).tap do |manager|
          instance_variable_set("@#{name}_manager", manager)
          yield(manager) if block_given?
        end
      end
    end
  end
end
