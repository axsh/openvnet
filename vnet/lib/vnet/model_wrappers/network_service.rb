# -*- coding: utf-8 -*-

module Vnet::ModelWrappers
  class NetworkService < Base
    def to_hash
      interface = self.batch.interface.commit
      {
        :uuid => self.uuid,
        :interface_uuid => interface && interface.uuid,
        :display_name => self.display_name,
        :incoming_port => self.incoming_port,
        :outgoing_port => self.outgoing_port,
        :created_at => self.created_at,
        :updated_at => self.updated_at
      }
    end
  end
end
