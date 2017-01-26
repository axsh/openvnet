# -*- coding: utf-8 -*-

# TODO: Rename to ManagerEvents

module Vnet
  module ManagerAssocs

    def self.included(klass)
      klass.include(InstanceMethods)
      klass.extend(ClassMethods)
    end

    module InstanceMethods

      def event_hash_assoc_pair(params, id_key)
        (params.is_a?(Hash) ? params.dup : params.to_hash).tap { |event_hash|
          event_hash[:id] = get_param_id(params, id_key)
          event_hash.delete(id_key)
        }
      end

    end

    module ClassMethods

      def subscribe_event_with_method(event, &block)
        "handle_#{event}".to_sym.tap { |method|
          subscribe_event event, method
          define_method method, block
        }
      end

      def subscribe_item_event(event, method)
        subscribe_event_with_method event do |params|
          begin
            (@items[get_param_id(params)] || return).tap { |item|
              item.send(method, params)
            }

            return nil
          rescue Vnet::ParamError => e
            return handle_param_error(e)
          end
        end
      end

      def subscribe_assoc_other_events(self_name, other_name)
        subscribe_item_event "#{self_name}_added_#{other_name}", "added_#{other_name}"
        subscribe_item_event "#{self_name}_removed_#{other_name}", "removed_#{other_name}"
      end

      def subscribe_assoc_pair_events(self_name, assoc_name, first_name, second_name)
        subscribe_assoc_other_events self_name, first_name
        subscribe_assoc_other_events self_name, second_name

        ["#{self_name}_added_#{assoc_name}", "#{first_name}_id".to_sym, "#{second_name}_id".to_sym].tap { |event, first_key, second_key|
          subscribe_event_with_method event do |params|
            begin
              publish "#{self_name}_added_#{first_name}", event_hash_assoc_pair(params, second_key)
              publish "#{self_name}_added_#{second_name}", event_hash_assoc_pair(params, first_key)
            rescue Vnet::ParamError => e
              return handle_param_error(e)
            end
          end
        }

        ["#{self_name}_removed_#{assoc_name}", "#{first_name}_id".to_sym, "#{second_name}_id".to_sym].tap { |event, first_key, second_key|
          subscribe_event_with_method event do |params|
            begin
              publish "#{self_name}_removed_#{first_name}", event_hash_assoc_pair(params, second_key)
              publish "#{self_name}_removed_#{second_name}", event_hash_assoc_pair(params, first_key)
            rescue Vnet::ParamError => e
              return handle_param_error(e)
            end
          end
        }
      end

    end
  end
end
