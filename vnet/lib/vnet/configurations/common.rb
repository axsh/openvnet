# -*- coding: utf-8 -*-
module Vnet::Configurations
  class Common < Fuguta::Configuration
    cattr_accessor :paths
    self.paths = ::Vnet::CONFIG_PATH

    class << self
      def conf
        @conf ||= self.load
      end

      def load(*files)
        if files.blank?
          file_names.each do |name|
            path = paths.find do |path|
              File.exists?(File.join(path, name))
            end
            raise "Config file '#{name}' not found in #{paths.join(' ,')}" unless path
            files << File.join(path, name)
          end
        end
        super(*files)
      end

      def file_name
        name.demodulize.underscore + ".conf"
      end

      def file_names
        unless @file_names
          @file_names = []
          if superclass.respond_to?(:file_names)
            @file_names += superclass.file_names
          end
          @file_names << file_name
        end
        @file_names
      end
    end

    class DB < Fuguta::Configuration
      param :adapter, :default => "mysql2"
      param :host, :default => "localhost"
      param :database, :default => "vnet"
      param :port, :default => 3306
      param :user, :default => "root"
      param :password
    end

    param :db_uri

    DSL do
      def db(&block)
        @config[:db] = DB.new.tap {|db| db.parse_dsl(&block) if block }
        @config[:db_uri] = "#{@config[:db].adapter}://#{@config[:db].host}:#{@config[:db].port}/#{@config[:db].database}?user=#{@config[:db].user}&password=#{@config[:db].password}"
      end
    end

    class Registry < Fuguta::Configuration
      param :adapter, :default => "redis"
      param :host, :default => '127.0.0.1'
      param :port, :default => 6379
    end

    DSL do
      def registry(&block)
        @config[:registry] = Registry.new.tap {|c| c.parse_dsl(&block) if block }
      end
    end
  end
end
