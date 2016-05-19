# -*- coding: utf-8 -*-

module Sequel
  module Plugins
    module IpAddress
      def self.apply(model, opts=OPTS)
        model.many_to_one :interface
        model.many_to_one :mac_lease
        model.many_to_one :ip_address
        model.many_to_many :networks, :join_table => :ip_addresses, :left_key => :id, :left_primary_key => :ip_address_id, :right_key => :network_id

        model.class_eval do
          def network
            return @network if @network
            networks.first
          end

          def network_id
            return @network_id if @network_id
            @network_id = self.ip_address.try(:network_id)
          end

          def network_id=(network_id)
            unless network_id == self.network_id
              @network_id = network_id
              modified!(:network_id)
            end
            @network_id
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
          if @network
            valid_subnet, ipv4_nw_s, ipv4_s = Vnet::Helpers::IpAddress.valid_in_subnet(
              self.network, self.ipv4_address)

            if !valid_subnet
              errors.add(:ipv4_address, "IP Address #{ipv4_s} not in subnet #{ipv4_nw_s}.")
            end
          end
          errors.add(:network_id, 'cannot be empty') if self.network_id.blank?
          errors.add(:ipv4_address, 'cannot be empty') if self.ipv4_address.blank?
        end

        def before_save
          if self.mac_lease
            self.interface_id = self.mac_lease.interface_id
          end
          if @network_id
            if self.ip_address && self.ip_address.network_id != @network_id
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
              model.network = model.class.association_reflection(:network).associated_class[@network_id]
              @network = model.network
              model.save
            end
          end
          super
        end

        def to_hash
          super.merge({
            :network_id => self.network_id,
            :ipv4_address => self.ipv4_address,
          })
        end

      end
    end
  end
end
