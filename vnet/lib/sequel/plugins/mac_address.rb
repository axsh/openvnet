# -*- coding: utf-8 -*-

module Sequel
  module Plugins
    module MacAddress
      def self.apply(model, opts = OPTS)
        mac_address_assoc_name = (opts[:attr_name] ? :mac_address : :_mac_address)
        mac_address_attr_name = opts[:attr_name] || :mac_address
        mac_address_variable_name = "@#{mac_address_attr_name}".to_sym

        model.many_to_one mac_address_assoc_name, class: model.name.split(/::/).tap{|n| n[-1] = "MacAddress"}.join("::"), key: :mac_address_id
        model.many_to_many :segments, :join_table => :mac_addresses, :left_key => :id, :left_primary_key => :mac_address_id, :right_key => :segment_id

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

          def segment
            _mac_address.try(:segment)
          end

          def segment_id
            return _cached_segment_id if _cached_segment_id
            self._cached_segment_id = _mac_address.try(:segment_id)
          end

          def segment_id=(new_segment_id)
            if new_segment_id != segment_id
              self._cached_segment_id = new_segment_id
              modified!(:segment_id)
            end
            _cached_segment_id
          end

          private

          def _cached_mac_address
            instance_variable_get(mac_address_variable_name)
          end

          def _cached_mac_address=(a)
            instance_variable_set(mac_address_variable_name, a)
          end

          def _cached_segment_id
            instance_variable_get(:@segment_id)
          end

          def _cached_segment_id=(s)
            instance_variable_set(:@segment_id, s)
          end

          def _query_mac_address
            __send__(mac_address_assoc_name).try(:mac_address)
          end

          def _query_segment_id
            __send__(mac_address_assoc_name).try(:segment_id)
          end

        end
      end

      module InstanceMethods
        def validate
          super

          if new?
            errors.add(mac_address_attr_name, "missing mac address") if _cached_mac_address.nil? && _query_mac_address.nil?
          else
            if modified?(:segment_id) && _cached_segment_id != _query_segment_id
              errors.add(:segment_id, "changing segment is not supported")
            end

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
                self._cached_segment_id = m.segment_id
              else
                __send__("#{mac_address_assoc_name}=",
                         self.class.association_reflection(mac_address_assoc_name).associated_class.create(mac_address: _cached_mac_address, segment_id: _cached_segment_id))
              end
            }
          end

          super
        end

        def to_hash
          super.merge({
            mac_address_attr_name.to_sym => __send__(mac_address_attr_name),
            :segment_id => self.segment_id
          })
        end
      end
    end
  end
end
