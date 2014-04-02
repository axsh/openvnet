# -*- coding: utf-8 -*-

module Vnet::Openflow

  class LeasePolicyManager < Manager

    #
    # Events:
    #
    subscribe_event ADDED_LEASE_POLICY, :create_item
    subscribe_event REMOVED_LEASE_POLICY, :delete_item
    subscribe_event INITIALIZED_LEASE_POLICY, :install_item

    def update(params)
      debug log_format('update(params)',"#{params}")
      nil
    end

    # Basing this on code from network_manager.rb in a section marked
    # "Obsolete".  Is there a better non-obsolete way to do this?
    def find_by_interface(id)
      r = MW::LeasePolicy.batch.find_by_interface(id).commit(fill: [:interfaces, :networks])
      return r.first if r.kind_of? Array 
      return nil
    end

    #
    # Internal methods:
    #

    private

    #
    # Specialize Manager:
    #

    def select_filter_from_params(params)
      case
      when params[:id]   then {:id => params[:id]}
      when params[:uuid] then params[:uuid]
      when params[:interface_id] then params
      else
        # Any invalid params that should cause an exception needs to
        # be caught by the item_by_params_direct method.
        return nil
      end
    end

    def match_item?(item, params)
      debug log_format('match_item?(item, params)',"#{params}")
      return false if params[:id] && params[:id] != item.id
      return false if params[:uuid] && params[:uuid] != item.uuid
      if params[:interface_id]
        return false if item.interfaces.empty?
        return false if params[:interface_id] != item.interfaces.first.id
      end
      true
    end

    def select_item(filter)
      debug log_format('select_item(filter)',"#{filter}")
      if filter[:interface_id]
        find_by_interface(filter[:interface_id])
      else
        MW::LeasePolicy.batch[filter].commit(fill: [:interfaces, :networks])
      end
    end

    def item_initialize(item_map, params)
      debug log_format('item_initialize(item_map, params)',"#{params}")
      LeasePolicies::Base.new(dp_info: @dp_info, manager: self, map: item_map)
    end

    def initialized_item_event
      debug log_format('initialized_item_event',"")
      INITIALIZED_LEASE_POLICY
    end

    def create_item(params)
      debug log_format('create_item(params)',"#{params}")
      item = @items[params[:item_map].id]
      return unless item

      debug log_format("insert #{item.uuid}/#{item.id}")
      item
    end

    def install_item(params)
      debug log_format('install_item(params)',"#{params}")
      item = @items[params[:item_map].id]
      return nil if item.nil?

      item.install

      debug log_format("install #{item.uuid}/#{item.id}")
      item
    end

    def delete_item(item)
      debug log_format('delete_item(item)',"")
      @items.delete(item.id)

      item.uninstall
      item
    end

    #
    # Events:
    #

  end

end
