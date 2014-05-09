module Vnet::Services
  class VnetInfo
    MANAGER_NAMES = %w()

    MANAGER_NAMES.each do |name|
      attr_reader "#{name}_manager"
    end

    def initialize(params)
      initialize_managers
    end

    def managers
      MANAGER_NAMES.map { |name| __send__("#{name}_manager") }
    end

    private

    def initialize_managers
      MANAGER_NAMES.each do |name|
        instance_variable_set("@#{name}_manager", Vnet::Services.const_get("#{name.to_s.camelize}Manager").new(self))
      end
    end
  end
end
