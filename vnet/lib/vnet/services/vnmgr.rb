module Vnet::Services
  class Vnmgr
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :vnet_info

    def initialize
      @vnet_info = VnetInfo.new
      link_with_managers
    end

    def link_with_managers
      @vnet_info.initialize_managers do |manager|
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
