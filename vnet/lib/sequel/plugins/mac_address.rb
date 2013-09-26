# -*- coding: utf-8 -*-

module Sequel
  module Plugins
    module MacAddress
      def self.apply(model, opts=OPTS)
        model.many_to_one (opts[:attr_name] ? :mac_address : :_mac_address), class: model.name.split(/::/).tap{|n| n[-1] = "MacAddress"}.join("::"), key: :mac_address_id
        mac_address_attr_name = opts[:attr_name] || :mac_address

        model.class_eval do
          define_method :mac_address_attr_name do
            mac_address_attr_name
          end

          define_method :mac_address_association_name do
            opts[:attr_name] ? :mac_address : :_mac_address
          end

          define_method mac_address_attr_name do
            instance_variable_get("@#{mac_address_attr_name}") || (__send__(mac_address_association_name) ? __send__(mac_address_association_name).mac_address : nil)
          end

          define_method "#{mac_address_attr_name}=" do |mac_address|
            if mac_address != __send__(mac_address_attr_name)
              instance_variable_set("@#{mac_address_attr_name}", mac_address)
              modified!(mac_address_attr_name)
            end
          end
        end
      end

      module InstanceMethods
        def before_save
          if value = __send__(mac_address_attr_name)
            m = __send__(mac_address_association_name)
            if m && m.mac_address != value
              m.destroy
              __send__("#{mac_address_association_name}=", nil)
            end
            unless __send__(mac_address_association_name)
              __send__("#{mac_address_association_name}=", self.class.association_reflection(mac_address_association_name).associated_class.create(mac_address: value))
            end
          end
          super
        end

        def after_destroy
          super
          if associations[mac_address_association_name]
            associations[mac_address_association_name].destroy
          end
        end

        def to_hash
          values[mac_address_attr_name] = __send__(mac_address_attr_name)
          super
        end
      end
    end
  end
end
