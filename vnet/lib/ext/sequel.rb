# -*- coding: utf-8 -*-

require 'msgpack'
require 'sequel/sql'

module Sequel
  module SQL

    class BooleanExpression < ComplexExpression
      def self.from_msgpack_ext(data)
        MessagePack.unpack(data).tap { |h|
          return case h['op'].to_sym
                 when :IS then BooleanExpression::from_value_pairs([h['args'].first], :IS)
                 else
                   BooleanExpression::from_value_pairs(h['args'], h['op'].to_sym)
                 end
        }
      end

      def to_msgpack_ext
        {
          op: @op,
          args: @args
        }.to_msgpack.tap { |m|
          Celluloid::Logger.warn "XXXXXXXXXXXXXXXXXXXXXX #{self.inspect} to #{m.inspect}"
        }
      end
    end

  end
end

MessagePack::DefaultFactory.register_type(0x10, Sequel::SQL::BooleanExpression)
