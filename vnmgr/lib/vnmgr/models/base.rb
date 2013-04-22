
require 'sequel/model'

module Vnmgr::Models
  module Taggable
    UUID_TABLE='abcdefghijklmnopqrstuvwxyz0123456789'.split('').freeze
    UUID_REGEX=%r/^(\w+)-([#{UUID_TABLE.join}]+)/

    def self.uuid_prefix_collection
      @uuid_prefix_collection ||= {}
    end

    def self.find(uuid)
      raise ArgumentError, "Invalid uuid syntax: #{uuid}" unless uuid =~ UUID_REGEX
      upc = uuid_prefix_collection[$1.downcase]
      raise "Unknown uuid prefix: #{$1.downcase}" if upc.nil?
      upc[:class].find(:uuid=>$2)
    end

    module ClassMethods
      def uuid_prefix(prefix=nil)
        if prefix
          raise UUIDPrefixDuplication, "Found collision for uuid_prefix key: #{prefix}" if Taggable.uuid_prefix_collection.has_key?(prefix)

          Taggable.uuid_prefix_collection[prefix]={:class=>self}
          @uuid_prefix = prefix
        end

        @uuid_prefix || (superclass.uuid_prefix if superclass.respond_to?(:uuid_prefix)) || raise("uuid prefix is unset for:#{self}")
      end
    end

  end

  class Base < Sequel::Model
    plugin :validation_helpers

    def to_hash()
      self.values.dup
    end

    private
    def self.inherited(klass)
      super
      klass.set_dataset(db[klass.implicit_table_name])
      klass.class_eval {

        def self.taggable(uuid_prefix)
          return if self == Base
          self.plugin Taggable
          self.uuid_prefix(uuid_prefix)
        end

      }
    end
  end
end
