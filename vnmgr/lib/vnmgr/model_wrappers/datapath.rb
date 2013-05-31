# -*- coding: utf-8 -*-

module Vnmgr::ModelWrappers
  class Datapath < Base
    def to_hash
      {
        :uuid => self.uuid,
        :open_flow_controller_uuid => self.open_flow_controller_uuid,
        :display_name => self.display_name,
        :ipv4_address => self.ipv4_address,
        :is_connected => self.is_connected,
        :datapath_id => self.datapath_id,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end

    # Hack...
    def broadcast_mac_addr(nw_uuid)
      case nw_uuid
      when 'nw-vnet'
        case self.uuid
        when 'dp-node1' then Trema::Mac.new('08:00:27:10:00:01').value
        when 'dp-node2' then Trema::Mac.new('08:00:27:10:00:02').value
        else
          raise("FOOOFOO")
        end
      when 'nw-public'
        case self.uuid
        when 'dp-node1' then Trema::Mac.new('08:00:27:10:00:03').value
        when 'dp-node2' then Trema::Mac.new('08:00:27:10:00:04').value
        else
          raise("FOOOFOO")
        end
      else
        raise("FOOOFOOFOO")
      end
    end

  end
end
