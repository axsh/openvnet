# -*- coding: utf-8 -*-

module Sequel
  module Plugins
    module IpAddress
      def self.apply(model, opts=OPTS)
        model.many_to_one :ip_address
        model.many_to_many :networks, :join_table => :ip_addresses, :left_key => :id, :left_primary_key => :ip_address_id, :right_key => :network_id

        model.class_eval do
          def network
            networks.first
          end

          def network_uuid
            return @network_uuid if @network_uuid
            @network_uuid = self.ip_address.try(:network).try(:canonical_uuid)
          end

          def network_uuid=(network_uuid)
            unless network_uuid == self.network_uuid
              @network_uuid = network_uuid
              modified!(:network_uuid)
            end
            @network_uuid
          end

          def ipv4_address
            return @ipv4_address if @ipv4_address
            @ipv4_address = self.ip_address.try(:ipv4_address)
          end

          def ipv4_address=(ipv4_address)
            unless ipv4_address == self.ipv4_address
              @ipv4_address = ipv4_address
              modified!(:ipv4_address)
            end
            @ipv4_address
          end
        end
      end

      module InstanceMethods
        def validate
          super
          errors.add(:network_uuid, 'cannot be empty') if self.network_uuid.blank?
          errors.add(:ipv4_address, 'cannot be empty') if self.ipv4_address.blank?
        end

        def before_save
          if @network_uuid
            if self.ip_address && self.ip_address.network.canonical_uuid != @network_uuid
              self.ip_address.destroy
              self.ip_address = nil
            end
          end
          if @ipv4_address
            if self.ip_address && self.ip_address.ipv4_address != @ipv4_address
              self.ip_address.destroy
              self.ip_address = nil
            end
          end
          unless self.ip_address
            self.ip_address = self.class.association_reflection(:ip_address).associated_class.new(ipv4_address: @ipv4_address).tap do |model|
              model.network = model.class.association_reflection(:network).associated_class[@network_uuid]
              model.save
            end
          end
          super
        end

        def after_destroy
          super
          self.ip_address.try(:destroy)
        end

        def to_hash
          super.merge({
            :network_uuid => self.network_uuid,
            :ipv4_address => self.ipv4_address,
          })
        end
      end
    end
  end
end
