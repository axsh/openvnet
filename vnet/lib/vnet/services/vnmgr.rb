module Vnet::Services
  class Vnmgr
    include Celluloid
    include Celluloid::Logger
    attr_reader :vnet_info

    def initialize
      link_with_managers
    end

    def link_with_managers
      @dp_info.managers.each do |manager|
        begin
          link(manager)
        rescue => e
          error "Fail to link with #{manager.class.name}: #{e}"
          raise e
        end
      end
    end
  end
end
