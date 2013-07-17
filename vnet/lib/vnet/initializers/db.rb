# -*- coding: utf-8 -*-

require 'sequel'

module Vnet::Initializers
  class DB
    def self.run(connection_string, options = {})
      #TODO: Figure out where to get this thing from
      db = Sequel.connect(connection_string)

      # Force to set "READ COMMITTED" isolation level.
      # This mode is supported by both InnoDB and MySQL Cluster backends.
      db.transaction_isolation_level = :committed

      if ENV['DEBUG_SQL'] || options[:debug_sql]
        require 'logger'
        db.loggers << Logger.new(STDERR)
      end
      case db.adapter_scheme
      when :mysql, :mysql2
        Sequel::MySQL.default_charset = 'utf8'
        Sequel::MySQL.default_collate = 'utf8_general_ci'
        Sequel::MySQL.default_engine = ENV['MYSQL_DB_ENGINE'] || 'InnoDB'

        # this is the mysql adapter specific constants. won't work with mysql2.
        if db.adapter_scheme == :mysql
          # Disable TEXT to Sequel::SQL::Blob translation.
          # see the thread: MySQL text turning into blobs
          # http://groups.google.com/group/sequel-talk/browse_thread/thread/d0f4c85abe9b3227/9ceaf291f90111e6
          # lib/sequel/adapters/mysql.rb
          [249, 250, 251, 252].each { |v|
            Sequel::MySQL::MYSQL_TYPES.delete(v)
          }
        end
      end
      Vnet::Models::Base.default_row_lock_mode = nil

      # Set timezone to UTC
      Sequel.default_timezone = :utc
    end
  end
end
