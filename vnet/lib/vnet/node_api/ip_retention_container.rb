# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class IpRetentionContainer < EventBase
    class << self

      # TODO: This should call ip_retention's node_api directly.

      def add_ip_retention(id, options)
        ip_retention_container = model_class[id]

        ip_retention = nil
        transaction do
          ip_retention = ip_retention_container.add_ip_retention(ip_lease_id: options[:ip_lease_id])
        end

        IpRetention.dispatch_created_for_model(ip_retention)

        ip_retention
      end

      def remove_ip_retention(id, ip_retention_id)
        ip_retention = model_class(:ip_retention)[ip_retention_id]

        return unless ip_retention.ip_retention_container_id == id

        transaction do
          ip_retention.destroy
        end

        IpRetention.dispatch_deleted_for_model(ip_retention)

        ip_retention
      end

      #
      # Internal methods:
      #

      private

      def dispatch_created_item_events(model)
        dispatch_event(IP_RETENTION_CONTAINER_CREATED_ITEM, model.to_hash)
      end

      def dispatch_deleted_item_events(model)
        dispatch_event(IP_RETENTION_CONTAINER_DELETED_ITEM, id: model.id)

        # 0002_services
        # ip_retentions: handled by main event?
        # lease_policy_ip_retention_containers: :destroy
      end

    end
  end
end
