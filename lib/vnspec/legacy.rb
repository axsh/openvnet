# -*- coding: utf-8 -*-
module Vnspec
  class Legacy
    include Config
    include SSH
    include Logger
    
    class << self
      include Config
      include Logger

      def setup
        config[:legacy].keys.map do |m|
          @@legacy_machines << self.new(m)
        end
      end

      def find(name)
        @@legacy_machines.find { |m| m.name == name }
      end
      alias :[] :find
    end

    def initialize(name)
      @name = name
    end
  end
end
