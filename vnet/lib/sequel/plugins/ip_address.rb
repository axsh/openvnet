# -*- coding: utf-8 -*-

module Sequel
  module Plugins
    module IpAddress
      def self.apply(model, opts=OPTS)
        model.many_to_one :ip_address
        model.class_eval do
          def ipv4_address
            return @ipv4_address if @ipv4_address
            @ipv4_address = ip_address.try(:ipv4_address)
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
        def before_save
          if @ipv4_address
            if ip_address && ip_address.ipv4_address != @ipv4_address
              ip_address.destroy
              ip_address = nil
            end
            unless ip_address
              self.ip_address = self.class.association_reflection(:ip_address).associated_class.create(ipv4_address: @ipv4_address)
            end
          end
          super
        end

        def after_destroy
          super
          ip_address.try(:destroy)
        end

        def to_hash
          super.merge({
            :ipv4_address => self.ipv4_address
          })
        end
      end
    end
  end
end
