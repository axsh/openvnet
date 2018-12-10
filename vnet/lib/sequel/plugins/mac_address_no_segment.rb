# -*- coding: utf-8 -*-

module Sequel
  module Plugins
    module MacAddressNoSegment
      def self.apply(model, opts = OPTS)
        mac_address_assoc_name = (opts[:attr_name] ? :mac_address : :_mac_address)
        mac_address_attr_name = opts[:attr_name] || :mac_address
        mac_address_variable_name = "@#{mac_address_attr_name}".to_sym

        model.many_to_one mac_address_assoc_name, class: model.name.split(/::/).tap{|n| n[-1] = "MacAddress"}.join("::"), key: :mac_address_id

        model.class_eval do
          define_method :mac_address_attr_name do
            mac_address_attr_name
          end

          define_method :mac_address_assoc_name do
            mac_address_assoc_name
          end

          define_method :mac_address_variable_name do
            mac_address_variable_name
          end

          define_method mac_address_attr_name do
            return _cached_mac_address if _cached_mac_address
            self._cached_mac_address = _query_mac_address
          end

          define_method "#{mac_address_attr_name}=" do |m_addr|
            if m_addr != send(mac_address_attr_name)
              self._cached_mac_address = m_addr
              modified!(mac_address_attr_name)
            end

            _cached_mac_address
          end

          private

          def _cached_mac_address
            instance_variable_get(mac_address_variable_name)
          end

          def _cached_mac_address=(a)
            instance_variable_set(mac_address_variable_name, a)
          end

          def _query_mac_address
            __send__(mac_address_assoc_name).try(:mac_address)
          end

        end
      end

      module InstanceMethods
        def validate
          super

          if new?
            errors.add(mac_address_attr_name, "missing mac address") if _cached_mac_address.nil? && _query_mac_address.nil?
          else
            if modified?(mac_address_attr_name) && _cached_mac_address != _query_mac_address
              errors.add(mac_address_attr_name, "changing mac address is not supported")
            end
          end
        end

        def before_save
          if new?
            __send__(mac_address_assoc_name).tap { |m|
              if m
                # TODO: Prioritize properly. Check new? when assigning, don't allow/update if already created?
                self._cached_mac_address = m.mac_address
              else
                __send__("#{mac_address_assoc_name}=",
                         self.class.association_reflection(mac_address_assoc_name).associated_class.create(mac_address: _cached_mac_address))
              end
            }
          end

          super
        end

        def to_hash
          super.merge({
            mac_address_attr_name.to_sym => __send__(mac_address_attr_name),
          })
        end
      end
    end
  end
end
