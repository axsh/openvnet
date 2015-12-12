# -*- coding: utf-8 -*-

require 'sequel/model'
require 'sequel/plugins/mac_address'
require 'sequel/plugins/ip_address'
require 'sequel/plugins/paranoia_is_deleted'
require 'sequel/plugins/dataset_associations.rb'
require 'sequel/plugins/many_through_many.rb'

Sequel.extension(:core_extensions)

module Vnet::Models

  # TODO: Refactor.
  class DeleteRestrictionError < StandardError; end

  # Sequel::Model plugin extends :schema plugin to merge the column
  # definitions in its parent class.
  #
  # class Model1 < Sequel::Model
  #   plugin InheritableSchema
  #
  #   inheritable_schema do
  #     String :col1
  #   end
  # end
  #
  # class Model2 < Model1
  #   inheritable_schema do
  #     String :col2
  #   end
  # end
  #
  # Model2.create_table!
  #
  # Then the schema for Model2 becomes as follows:
  #   primary_key :id, :type=>Integer, :unsigned=>true
  #   String :col1
  #   String :col2
  module InheritableSchema
    def self.apply(model)
      require 'sequel/plugins/schema'
      model.plugin Sequel::Plugins::Schema
    end

    module ClassMethods
      # Creates table, using the column information from set_schema.
      def create_table
        db.create_table(table_name, :generator=>schema)
        @db_schema = get_db_schema(true)
        columns
      end

      # Drops the table if it exists and then runs
      # create_table.  Should probably
      # not be used except in testing.
      def create_table!
        drop_table rescue nil
        create_table
      end

      # Creates the table unless the table already exists
      def create_table?
        create_table unless table_exists?
      end

      # Drops table.
      def drop_table
        db.drop_table(table_name)
      end

      # Returns true if table exists, false otherwise.
      def table_exists?
        db.table_exists?(table_name)
      end

      def schema
        builders = []
        c = self
        begin
          builders << c.schema_builders if c.respond_to?(:schema_builders)
        end while((c = c.superclass) && c != Sequel::Model)

        builders = builders.reverse.flatten
        builders.delete(nil)

        schema = Sequel::Schema::Generator.new(db) {
          primary_key :id, Integer, :null=>false, :unsigned=>true
        }
        builders.each { |blk|
          schema.instance_eval(&blk)
        }
        set_primary_key(schema.primary_key_name) if schema.primary_key_name

        schema
      end

      def schema_builders
        @schema_builders ||= []
      end

      def inheritable_schema(name=nil, &blk)
        set_dataset(db[name || implicit_table_name])
        self.schema_builders << blk
      end
    end

  end

  # This plugin is to archive the changes on each column of the model
  # to a history table.
  #
  # plugin ArchiveChangedColumn, :your_history_table
  #  or
  # plugin ArchiveChangedColumn
  # history_dataset = DB[:history_table]
  #
  # The history table should have the schema below:
  # schema do
  #   Fixnum :id, :null=>false, :primary_key=>true
  #   String :uuid, :size=>50, :null=>false
  #   String :attr, :null=>false
  #   String :vchar_value, :null=>true
  #   String :blob_value, :null=>true, :text=>true
  #   Time  :created_at, :null=>false
  #   index [:uuid, :created_at]
  #   index [:uuid, :attr]
  # end
  module ArchiveChangedColumn
    def self.configure(model, history_table=nil)
      model.history_dataset = case history_table
                              when NilClass
                                nil
                              when String,Symbol
                                model.db.from(history_table)
                              when Class
                                raise "Unknown type" unless history_table < Sequel::Model
                                history_table.dataset
                              when Sequel::Dataset
                                history_table
                              else
                                raise "Unknown type"
                              end
    end

    module ClassMethods
      def history_dataset=(ds)
        @history_ds = ds
      end

      def history_dataset
        @history_ds
      end
    end

    module InstanceMethods
      def history_snapshot(at)
        raise TypeError unless at.is_a?(Time)

        if self.created_at > at || (!self.terminated_at.nil? && self.terminated_at < at)
          raise "#{at} is not in the range of the object's life span."
        end

        ss = self.dup
        #  SELECT * FROM (SELECT * FROM `instance_histories` WHERE
        #  (`uuid` = 'i-ezsrs132') AND created_at <= '2010-11-30 23:08:05'
        #  ORDER BY created_at DESC) AS a GROUP BY a.attr;
        ds = self.class.history_dataset.filter('uuid=? AND created_at <= ?', self.canonical_uuid, at).order(:created_at.desc)
        ds = ds.from_self.group_by(:attr)
        ds.all.each { |h|
          if !h[:blob_value].nil?
            ss.send("#{h[:attr]}=", typecast_value(h[:attr], h[:blob_value]))
          else
            ss.send("#{h[:attr]}=", typecast_value(h[:attr], h[:vchar_value]))
          end
        }
        # take care for serialized columns by serialization plugin.
        ss.deserialized_values.clear if ss.respond_to?(:deserialized_values)

        ss
      end

      def before_create
        return false if super == false
        store_changes(self.columns)
        true
      end

      def before_update
        return false if super == false
        store_changes(self.changed_columns)
        true
      end

      private
      def store_changes(cols_stored)
        return if cols_stored.nil? || cols_stored.empty?
        common_rec = {
          :uuid=>self.canonical_uuid,
          :created_at => Time.now,
        }

        cols_stored.each { |c|
          hist_rec = common_rec.dup
          hist_rec[:attr] = c.to_s

          coldef = self.class.db_schema[c]
          case coldef[:type]
          when :text,:blob
            hist_rec[:blob_value]= (new? ? (self[c] || coldef[:default]) : self[c])
          else
            hist_rec[:vchar_value]=(new? ? (self[c] || coldef[:default]) : self[c])
          end
          self.class.history_dataset.insert(hist_rec)
        }
      end
    end
  end

  module ChangedColumnEvent
    # This plugin is to call any method when each columns of model was changed.
    #
    # Usage:
    #
    #   plugin ChangedColumnEvent, :function_name => [:track_columns]
    #
    #   * :function_name - specify name that called by :track_columns event. Please create a function that added with a on_changed_ prefix. ( eg: on_changed_accounting_log)
    #   * :track_columns - specify columns that can call :function_name when the table has been changed.

    def self.configure(model, track_columns)
      raise "Invalid type" if !track_columns.is_a?(Hash)
      track_columns.keys.each { |event_name|
        model.track_column_set(event_name, track_columns)
      }
    end

    module ClassMethods
      attr_accessor :track_columns
      def track_column_set(event_name, columns)
        @track_columns = {} if @track_columns.nil?
        @track_columns[event_name] = columns
      end
    end

    module InstanceMethods
      def before_create
        return false if super == false
        apply_changed_event(self.columns)
        true
      end

      def before_update
        return false if super == false
        apply_changed_event(self.changed_columns)
        true
      end

      private
      def apply_changed_event(changed_columns)
        model.track_columns.keys.each do |event_name|
          call_method = "on_changed_#{event_name.to_s}".to_sym
          raise "Undefined method #{call_method}" if !model.method_defined?(call_method)

          model.track_columns[event_name].values.find_all { |c|
            match_column = c - (c - changed_columns)
            self.__send__(call_method, match_column[0])  if !match_column.empty?
          }
        end
      end
    end
  end

  class Base < Sequel::Model

    plugin :dataset_associations
    plugin :many_through_many
    plugin :validation_helpers

    db.extension :pagination

    def to_hash()
      self.values.dup.merge({:class_name => self.class.name.demodulize})
    end

    LOCK_TABLES_KEY='__locked_tables'

    def self.default_row_lock_mode=(mode)
      raise ArgumentError unless [nil, :share, :update].member?(mode)
      @default_row_lock_mode = mode
    end

    def self.lock!(mode=nil)
      raise ArgumentError unless [nil, :share, :update].member?(mode)
      mode ||= @default_row_lock_mode
      locktbls = Thread.current[LOCK_TABLES_KEY]
      if locktbls
        locktbls[self.db.uri.to_s + @dataset.first_source_alias.to_s]=mode
      end
    end

    def self.unlock!
      locktbls = Thread.current[LOCK_TABLES_KEY]
      if locktbls
        locktbls.delete(self.db.uri.to_s + @dataset.first_source_alias.to_s)
      end
    end

    def self.dataset
      locktbls = Thread.current[LOCK_TABLES_KEY]
      if locktbls && (mode = locktbls[self.db.uri.to_s + @dataset.first_source_alias.to_s])
        # lock mode: :share or :update
        @dataset.extension(:sequel_3_dataset_methods).opts = @dataset.extension(:sequel_3_dataset_methods).opts.merge({:lock=>mode})
      else
        @dataset.extension(:sequel_3_dataset_methods).opts = @dataset.extension(:sequel_3_dataset_methods).opts.merge({:lock=>nil})
      end
      @dataset
    end

    def self.Proxy(klass)
      colnames = klass.schema.columns.map {|i| i[:name] }
      colnames.delete_if(klass.primary_key) if klass.restrict_primary_key?
      s = ::Struct.new(*colnames) do
        def to_hash
          n = {}
          self.each_pair { |k,v|
            n[k.to_sym]=v
          }
          n
        end
      end
      s
    end

    # Returns true if this Model has time stamps
    def with_timestamps?
      self.columns.include?(:created_at) && self.columns.include?(:updated_at)
    end

    # Callback when the initial data is setup to the database.
    def self.install_data
      install_data_hooks.each{|h| h.call }
    end

    # Add callbacks to setup the initial data. The hooks will be
    # called when Model1.install_data() is called.
    #
    # class Model1 < Base
    #   install_data_hooks do
    #     Model1.create({:col1=>1, :col2=>2})
    #   end
    # end
    def self.install_data_hooks(&blk)
      @install_data_hooks ||= []
      if blk
        @install_data_hooks << blk
      end
      @install_data_hooks
    end


    private

    def self.inherited(klass)
      super
      klass.set_dataset(db[klass.implicit_table_name])

      klass.plugin InheritableSchema
      klass.plugin :timestamps, :update_on_create=>true
      klass.class_eval {

        # Add timestamp columns and set callbacks using Timestamps
        # plugin.
        #
        # class Model1 < Base
        #   with_timestamps
        # end
        def self.with_timestamps
          self.schema_builders << proc {
            unless has_column?(:created_at)
              column(:created_at, Time, :null=>false)
            end
            unless has_column?(:updated_at)
              column(:updated_at, Time, :null=>false)
            end
          }

          self.plugin :timestamps, :update_on_create=>true
        end

        # Install taggable module as Sequel plugin and set uuid_prefix.
        #
        # class Model1 < Base
        #   taggable 'm'
        # end
        def self.taggable(uuid_prefix)
          return if self == Base
          self.plugin :after_initialize
          self.plugin BaseTaggable
          self.uuid_prefix(uuid_prefix)
        end
      }
    end

  end
end
