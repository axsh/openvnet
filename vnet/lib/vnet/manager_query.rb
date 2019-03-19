# -*- coding: utf-8 -*-

require 'sequel/core'
require 'sequel/sql'

module Vnet
  class Manager
    module Query
      private

      def init_query
        @load_queries = {}
      end
      
      def has_query?(params)
        @load_queries.has_key?(params)
      end

      # Query to load the first item that matches <params>.
      def start_query(params, &block)
        if @load_queries.has_key?(params)
          raise "Called start_query with has_query?(#{params.inspect})."
        end

        begin
          @load_queries[params] = :querying

          if params.has_key?(:uuid) && params[:uuid].nil?
            raise Vnet::Manager::ParamError.new("Called start_query with invalid uuid parameter.")
          end

          create_query_batch(mw_class.batch, get_param_string_n(params, :uuid, false), query_filter_from_params(params)).tap { |select_filter|
            select_item(select_filter.first).tap { |item_map|
              block.call(item_map)
            }
          }

          return nil
        ensure
          clear_query(params)
        end        
      end

      def clear_query(params)
        if !@load_queries.has_key?(params)
          raise "Called clear_query without has_query?(#{params.inspect})."
        end

        @load_queries.delete(params)
      end

      # Creates a batch object for querying a set of item to load,
      # excluding the 'uuid' parameter.
      def query_filter_from_params(params)
        # Must be implemented by subclass
        raise NotImplementedError
      end

      # We explicity initialize each proc parts into the method's local
      # context, and create the block by referencing those for
      # optimization reasons.
      def match_item_proc(params)
        case params.size
        when 1
          part_1 = params.to_a.first
          match_item_proc_part(part_1)
        when 2
          part_1, part_2 = params.to_a
          part_1 = match_item_proc_part(part_1)
          part_2 = match_item_proc_part(part_2)
          part_1 && part_2 &&
            proc { |id, item|
            part_1.call(id, item) &&
              part_2.call(id, item)
          }
        when 3
          part_1, part_2, part_3 = params.to_a
          part_1 = match_item_proc_part(part_1)
          part_2 = match_item_proc_part(part_2)
          part_3 = match_item_proc_part(part_3)
          part_1 && part_2 && part_3 &&
            proc { |id, item|
            part_1.call(id, item) &&
              part_2.call(id, item) &&
              part_3.call(id, item)
          }
        when 4
          part_1, part_2, part_3, part_4 = params.to_a
          part_1 = match_item_proc_part(part_1)
          part_2 = match_item_proc_part(part_2)
          part_3 = match_item_proc_part(part_3)
          part_4 = match_item_proc_part(part_4)
          part_1 && part_2 && part_3 && part_4 &&
            proc { |id, item|
            part_1.call(id, item) &&
              part_2.call(id, item) &&
              part_3.call(id, item) &&
              part_4.call(id, item)
          }
        when 0
          proc { |id, item| true }
        else
          raise NotImplementedError, params.inspect
        end
      end

      def match_item_proc_part(filter_part)
        raise NotImplementedError, params.inspect
      end

      # The default select call with no fill options.
      #
      # TODO: Deprecate this.
      def select_item(batch)
        batch.commit
      end

      #
      # Internal:
      #

      def create_query_batch(batch, uuid, filters)
        expression = (filters.size > 1) ? Sequel.&(*filters) : filters.first

        return unless expression || uuid

        dataset = uuid ? batch.dataset_where_uuid(uuid) : batch.dataset
        dataset = expression ? dataset.where(expression) : dataset
      end

    end
  end
end
