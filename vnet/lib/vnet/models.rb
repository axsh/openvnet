require "celluloid"
require "sequel"

# Managing database connection and transaction.
# 
# The DB connection of Sequel is created per the running thread. To
# control the number connection, we need a connection manager that
# also handles with DB transaction.
#
# There is a rule to use Models.transaction()/#transaction() method:
#   1. Every models class operation has to happen in the block.
#
# transaction() method sends the block to DB thread then the
# developers can let the actor handle transaction and connection
# management.
#
# Currently it is designed and limited to issue queries on one DB
# thread since the code base seems to have problematic queries with
# data consistency. It is planned to have multiple DB threads with
# pool mechanism later.
#
# Example:
#
# p Vnet::Models.transaction do
#   # Executed in ModelActor's thread.
#   Vnet::Models::Interface.first
# end
#
# class A
#   include Vnet::Models
#   def do
#     transaction do
#       # Executed in ModelActor's thread.
#       Models::Interface.create(....)
#     end
#   end
# end
module Vnet
  module Models
    class ModelActor
      include Celluloid
      execute_block_on_receiver :transact

      def transact(opts, &blk)
        if opts.nil?
          opts = Sequel::OPTS
        end
        Sequel::Model.db.transaction(opts) do |conn|
          yield conn
        end
      end
    end

    ModelActor.supervise_as :model_actor

    def self.transaction(opts=nil, &blk)
      Celluloid::Actor[:model_actor].transact(opts, &blk)
    end

    def transaction(opts=nil, &blk)
      Models.transaction(opts, &blk)
    end
  end
end

require_relative "models/active_interface"
require_relative "models/datapath_network"
require_relative "models/datapath"
require_relative "models/datapath_route_link"
require_relative "models/dns_record"
require_relative "models/dns_service"
require_relative "models/interface_port"
require_relative "models/interface"
require_relative "models/ip_address"
require_relative "models/ip_lease_container_ip_lease"
require_relative "models/ip_lease_container"
require_relative "models/ip_lease"
require_relative "models/ip_range_group"
require_relative "models/ip_range"
require_relative "models/ip_retention_container"
require_relative "models/ip_retention"
require_relative "models/lease_policy_base_interface"
require_relative "models/lease_policy_base_network"
require_relative "models/lease_policy_ip_lease_container"
require_relative "models/lease_policy_ip_retention_container"
require_relative "models/lease_policy"
require_relative "models/mac_address"
require_relative "models/mac_lease"
require_relative "models/network"
require_relative "models/network_service"
require_relative "models/route_link"
require_relative "models/route"
require_relative "models/security_group_interface"
require_relative "models/security_group"
require_relative "models/translation"
require_relative "models/translation_static_address"
require_relative "models/tunnel"
require_relative "models/vlan_translation"
