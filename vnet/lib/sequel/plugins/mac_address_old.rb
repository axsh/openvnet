# -*- coding: utf-8 -*-

module Sequel
  module Plugins
    module MacAddressOld
      def self.apply(model, opts = OPTS)
        association_name = (opts[:attr_name] ? :mac_address : :_mac_address)
        mac_address_attr_name = opts[:attr_name] || :mac_address
        
        model.many_to_one association_name, class: model.name.split(/::/).tap{|n| n[-1] = "MacAddress"}.join("::"), key: :mac_address_id
        model.many_to_many :segments, :join_table => :mac_addresses, :left_key => :id, :left_primary_key => :mac_address_id, :right_key => :segment_id

        model.class_eval do
          define_method :mac_address_attr_name do
            mac_address_attr_name
          end

          define_method :mac_address_assoc_name do
            association_name
          end

          define_method mac_address_attr_name do
            return instance_variable_get("@#{mac_address_attr_name}") if instance_variable_get("@#{mac_address_attr_name}")
            instance_variable_set("@#{mac_address_attr_name}", __send__(mac_address_assoc_name) ? __send__(mac_address_assoc_name).mac_address : nil)
          end

          define_method "#{mac_address_attr_name}=" do |mac_address|
            if mac_address != __send__(mac_address_attr_name)
              instance_variable_set("@#{mac_address_attr_name}", mac_address)
              modified!(mac_address_attr_name)
            end
            instance_variable_get("@#{mac_address_attr_name}")
          end

          def segment
            return @segment if @segment
            segments.first
          end

          def segment_id
            return @segment_id if @segment_id
            @segment_id = _mac_address.try(:segment_id)
          end

          def segment_id=(new_segment_id)
            if new_segment_id != segment_id
              @segment_id = new_segment_id
              modified!(:segment_id)
            end
            @segment_id
          end

        end
      end

      module InstanceMethods
        def before_save
          if value = __send__(mac_address_attr_name)
            m = __send__(mac_address_assoc_name)

            if m && m.mac_address != value
              m.destroy
              __send__("#{mac_address_assoc_name}=", nil)
            end

            unless __send__(mac_address_assoc_name)
              __send__("#{mac_address_assoc_name}=", self.class.association_reflection(mac_address_assoc_name).associated_class.create(mac_address: value, segment_id: @segment_id))
            end
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
