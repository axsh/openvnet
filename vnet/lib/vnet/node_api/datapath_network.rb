# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class DatapathNetwork < Base
    class << self

      def create(options)
        options = options.dup

        dp_obj = transaction {

          if options[:ip_lease_id].nil?
            options[:ip_lease_id] = find_ip_lease_id(options[:interface_id])
          end

          model_class.create(options)

        }.tap { |dp_obj|
          # TODO: Fix...
          dp_obj && dispatch_event(ADDED_DATAPATH_NETWORK,
                                   id: dp_obj.datapath_id,
                                   network_id: dp_obj.network_id,
                                   dpn_id: dp_obj.id)
        }
      end

      def destroy(datapath_id: datapath_id, network_id: network_id)
        transaction {
          model_class.find(datapath_id: datapath_id, network_id: network_id).tap(&:destroy)
        }.tap do |dp_obj|
          dp_obj && dispatch_event(REMOVED_DATAPATH_NETWORK,
                                id: dp_obj.datapath_id,
                                network_id: dp_obj.network_id,
                                dpn_id: dp_obj.id)
        end
      end

      private

      def find_ip_lease_id(interface_id)
        return if interface_id.nil?

        ip_lease = model_class(:ip_lease).dataset.where(interface_id: interface_id).first
        ip_lease && ip_lease.id
      end

    end
  end
end
