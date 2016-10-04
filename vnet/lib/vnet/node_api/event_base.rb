# -*- coding: utf-8 -*-

module Vnet::NodeApi
  class EventBase < Base
    class << self

      def create(options)
        create_with_transaction(options).tap { |model|
          next if model.nil?
          dispatch_created_item_events(model)
        }
      end

      def update_uuid(uuid, changes)
        update_model(model_class[uuid], changes)
      end

      def update_model(model, changes)
        if has_valid_update_fields?
          validate_update_fields(changes)
        end

        update_model_no_validate(model, changes)
      end

      def update_model_no_validate(model, changes)
        internal_update(model, changes).tap { |model, changed_keys|
          return model if model.nil? || changed_keys.nil?
          dispatch_updated_item_events(model, changed_keys)
          return model
        }
      end

      def destroy(filter)
        destroy_with_transaction(filter).tap { |model|
          next if model.nil?
          dispatch_deleted_item_events(model)
        }
      end

      # Make sure events are dispatched for entries deleted by
      # sequel's association_dependencies plugin. We send events for
      # all entries with 'deleted_at' within the last 3 seconds in
      # order to account for the possibility that the two timestamps
      # are mismatched.
      #
      # Note: Investigate if parent's deleted_at always gets written
      # last, if so remove the 3 second grace time.

      def dispatch_created_for_model(model)
        dispatch_created_item_events(model)
      end

      def dispatch_deleted_for_model(model)
        dispatch_deleted_item_events(model)
      end

      def dispatch_created_where(filter, created_at)
        filter_date = ['created_at <= ?', created_at + 3]

        model_class.where(filter).filter(*filter_date).each { |model|
          dispatch_created_item_events(model)
        }
      end

      def dispatch_deleted_where(filter, deleted_at)
        filter_date = ['deleted_at >= ? || deleted_at = NULL',
                       (deleted_at || Time.now) - 3]

        model_class.with_deleted.where(filter).filter(*filter_date).each { |model|
          dispatch_deleted_item_events(model)
        }
      end

      # TODO: Move to a plugin.
      def mac_address_random_assign(options)
        mac_address = options[:mac_address]
        mac_group_uuid = Vnet::Configurations::Common.conf.datapath_mac_group

        if mac_address.nil? && mac_group_uuid
          mac_group = model_class(:mac_range_group)[mac_group_uuid] || return
          mac_address = mac_group.address_random || return

          options[:mac_address_id] = mac_address.id
        end
      end

      #
      # Internal methods:
      #

      private

      #
      # Customizable methods:
      #

      # Allows the model to be created/deleted within a
      # transaction. The overloading method needs to add the
      # transaction block and call internal_create/delete.

      def create_with_transaction(options)
        model_class.create(options)
      end

      def destroy_with_transaction(filter)
        internal_destroy(model_class[filter])
      end

      def dispatch_created_item_events(model)
        raise NotImplementedError
      end

      def dispatch_updated_item_events(model, changed_keys)
        raise NotImplementedError
      end

      def dispatch_deleted_item_events(model)
        raise NotImplementedError
      end

      #
      # Internal EventBase methods:
      #

      def internal_create(options)
        model_class.create(options)
      end

      def internal_destroy(model)
        model && model.destroy
      end

      def internal_update(model, options)
        model && model.update(options) && [model, options.keys]
      end

      def get_changed_hash(model, changed_keys)
        {id: model.id}.tap { |values|
          changed_keys.each { |key|
            values[key] = model[key]
          }
        }
      end

      def inherited(klass)
        super
        klass.class_eval {

          # Install mode module as Sequel plugin.
          #
          # class Foo < Base
          #   valid_update_fields [:foo, :bar]
          # end
          def self.valid_update_fields(fields)
            return if self == Base

            self.plugin BaseValidateUpdateFields
            self.set_valid_update_fields(fields)
          end
        }
      end

    end
  end
end
