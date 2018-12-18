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

      def start_query(params)
        if @load_queries.has_key?(params)
          raise "Called start_query with has_query?(#{params.inspect})."
        end

        @load_queries[params] = :querying

        if params.has_key?(:uuid) && params[:uuid].nil?
          raise Vnet::Manager::ParamError.new("Called start_query with invalid uuid parameter.")
        end

        create_query_batch(mw_class.batch, get_param_string_n(params, :uuid, false), query_filter_from_params(params))
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
