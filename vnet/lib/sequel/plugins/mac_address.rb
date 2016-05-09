# -*- coding: utf-8 -*-

module Sequel
  module Plugins
    module MacAddress
      def self.apply(model, opts = OPTS)
        association_name = (opts[:attr_name] ? :mac_address : :_mac_address)
        mac_address_attr_name = opts[:attr_name] || :mac_address

        model.many_to_many :segments, :join_table => :mac_addresses, :left_key => :id, :left_primary_key => :mac_address_id, :right_key => :segment_id
        model.many_to_one association_name, class: model.name.split(/::/).tap{|n| n[-1] = "MacAddress"}.join("::"), key: :mac_address_id

        model.class_eval do
          define_method :mac_address_attr_name do
            mac_address_attr_name
          end

          define_method :mac_address_association_name do
            association_name
          end

          define_method mac_address_attr_name do
            if instance_variable_get("@#{mac_address_attr_name}")
              return instance_variable_get("@#{mac_address_attr_name}")
            end

            result = __send__(mac_address_association_name)

            instance_variable_set("@#{mac_address_attr_name}", result && result.mac_address)
          end

          # TODO: Remove as it should be read-only? Same for ip_address.
          define_method "#{mac_address_attr_name}=" do |mac_address|
            if mac_address != __send__(mac_address_attr_name)
              instance_variable_set("@#{mac_address_attr_name}", mac_address)
              modified!(mac_address_attr_name)
            end

            instance_variable_get("@#{mac_address_attr_name}")
          end

          def segment
            @segment || segments.first
          end

          def segment_id
            return @segment_id if @segment_id

            result = __send__(mac_address_association_name)

            @segment_id = result && result.segment_id
          end

          def segment_id=(segment_id)
            if segment_id != self.segment_id
              @segment_id = segment_id
              modified!(:segment_id)
            end

            @segment_id
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

            if __send__(mac_address_association_name).nil?
              assoc_class = self.class.association_reflection(mac_address_association_name).associated_class

              __send__("#{mac_address_association_name}=",
                assoc_class.create(mac_address: value, segment_id: @segment_id))
            end
          end

          super
        end

        def to_hash
          super.merge({mac_address_attr_name.to_sym => __send__(mac_address_attr_name),
                       :segment_id => segment_id})
        end

      end
    end
  end
end
