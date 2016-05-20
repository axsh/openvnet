# -*- coding: utf-8 -*-

module Sequel
  module Plugins
    module MacAddress
      def self.apply(model, opts = OPTS)
        mac_address_assoc_name = (opts[:attr_name] ? :mac_address : :_mac_address)
        mac_address_attr_name = opts[:attr_name] || :mac_address

        segment_assoc_name = (opts[:segment_name] ? :segments : :_segments)
        segment_opt_name = opts[:segment_name]

        if segment_opt_name
          segment_attr_name = segment_opt_name.to_s.to_sym
          segment_attr_id = (segment_opt_name.to_s + '_id').to_sym
        else
          segment_attr_name = :segment
          segment_attr_id = :segment_id
        end

        model.many_to_many segment_assoc_name, :join_table => :mac_addresses, :left_key => :id, :left_primary_key => :mac_address_id, :right_key => :segment_id
        model.many_to_one mac_address_assoc_name, class: model.name.split(/::/).tap{|n| n[-1] = "MacAddress"}.join("::"), key: :mac_address_id

        model.class_eval do
          define_method :mac_address_attr_name do
            mac_address_attr_name
          end

          define_method :mac_address_assoc_name do
            mac_address_assoc_name
          end

          define_method :segment_attr_name do
            segment_attr_name
          end

          define_method :segment_attr_id do
            segment_attr_id
          end

          define_method :segment_assoc_name do
            segment_assoc_name
          end

          define_method mac_address_attr_name do
            if instance_variable_get("@#{mac_address_attr_name}")
              return instance_variable_get("@#{mac_address_attr_name}")
            end

            result = __send__(mac_address_assoc_name)

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

          define_method segment_attr_name do
            if instance_variable_get("@#{segment_attr_name}")
              return instance_variable_get("@#{segment_attr_name}")
            end

            result = __send__(mac_address_assoc_name)

            instance_variable_set("@#{segment_attr_name}", result && result.segment)
          end

          define_method segment_attr_id do
            if instance_variable_get("@#{segment_attr_id}")
              return instance_variable_get("@#{segment_attr_id}")
            end

            result = __send__(mac_address_assoc_name)

            instance_variable_set("@#{segment_attr_id}", result && result.segment_id)
          end

          # TODO: Remove?
          define_method "#{segment_attr_name}=" do |segment|
            if segment != __send__(segment_attr_name)
              instance_variable_set("@#{segment_attr_name}", segment)
              modified!(segment_attr_name)
            end

            instance_variable_get("@#{segment_attr_name}")
          end

          define_method "#{segment_attr_id}=" do |segment|
            if segment != __send__(segment_attr_id)
              instance_variable_set("@#{segment_attr_id}", segment)
              modified!(segment_attr_id)
            end

            instance_variable_get("@#{segment_attr_id}")
          end

        end
      end

      module InstanceMethods
        def before_save
          save_mac_address = __send__(mac_address_attr_name)
          save_segment_id = __send__(segment_attr_id)

          if save_mac_address
            if __send__(mac_address_assoc_name).nil?
              assoc_class = self.class.association_reflection(mac_address_assoc_name).associated_class

              __send__("#{mac_address_assoc_name}=", assoc_class.create(mac_address: save_mac_address, segment_id: save_segment_id))
            end
          end

          super
        end

        def to_hash
          super.merge({mac_address_attr_name => __send__(mac_address_attr_name),
                       segment_attr_name => segment_id})
        end

      end
    end
  end
end
