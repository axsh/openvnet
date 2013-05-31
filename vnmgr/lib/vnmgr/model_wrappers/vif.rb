# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class Vif < Base
    def to_hash
      {
        :uuid => self.uuid,
        :network_id => self.network_id,
        :mac_addr => self.mac_addr,
        :state => self.state,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end

    # Hack...
    def ipv4_addr
      case self.uuid
      when 'vif-ga40cmta' then IPAddr.new('192.168.60.220').to_i
      when 'vif-nh44un1v' then IPAddr.new('192.168.60.221').to_i
      when 'vif-zbnm1onh' then IPAddr.new('10.102.0.10').to_i
      when 'vif-rmxtdhyx' then IPAddr.new('10.102.0.11').to_i
      else
        raise('unknown vif uuid for hack')
      end
    end

  end
end
