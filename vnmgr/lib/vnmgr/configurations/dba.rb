# -*- coding: utf-8 -*-

module Vnmgr
  module Configurations
    class Dba < Common
      param :node_name, :default => "dba"
      param :actor_names, :default => %w(dba)
      param :ip
      param :port

      DSL do
        def actor_names(*names)
          @config[:actor_names] ||={}
          @config[:actor_names] = names
        end
      end
    end
  end
end
