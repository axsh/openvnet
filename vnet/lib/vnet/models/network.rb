# -*- coding: utf-8 -*-

module Vnet::Models

  # TODO: Refactor. Make sure all associate dependencies cause events.

  class Network < Base
    taggable 'nw'

    plugin :paranoia_is_deleted

    one_to_many :tunnels
    one_to_many :ip_addresses

    one_to_many :datapath_networks
    many_to_many :datapaths, :join_table => :datapath_networks, :conditions => "datapath_networks.deleted_at is null"

    many_to_many :lease_policies, :join_table => :lease_policy_base_networks, :conditions => "lease_policy_base_networks.deleted_at is null"
    one_to_many :lease_policy_base_networks

    def before_destroy
      [DatapathNetwork, IpAddress, Route, VlanTranslation].each do |klass|
        if klass[network_id: id]
          raise DeleteRestrictionError, "cannot delete network(id: #{id}) if any dependency still exists. dependency: #{klass}"
        end
      end
    end

  end
end
