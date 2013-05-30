
# -*- coding: utf-8 -*-

module Vnmgr::Configurations
  class Common < Fuguta::Configuration
    class DB < Fuguta::Configuration
      param :adapter, :default => "mysql2"
      param :host, :default => "localhost"
      param :database, :default => "vnmgr"
      param :port, :default => 3306
      param :user, :default => "root"
      param :password
    end

    param :redis_host, :default => '127.0.0.1'
    param :redis_port, :default => 6379
    param :db_uri

    def db(&block)
      @config[:db] = DB.new.tap {|db| db.parse_dsl(&block) if block }
      @config[:db_uri] = "#{@config[:db].adapter}://#{@config[:db].host}:#{@config[:db].port}/#{@config[:db].database}?user=#{@config[:db].user}&password=#{@config[:db].password}"
    end
  end
end
