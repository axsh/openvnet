# -*- coding: utf-8 -*-

require 'msgpack'
require 'sequel/sql'

class Time
  def to_msgpack_ext
    [tv_sec, tv_nsec].pack('I*')
  end

  def self.from_msgpack_ext(data)
    data.unpack('I*').tap { |s, n| at(s, Rational(n, 1000)) }
  end
end

module Sequel
  module SQL

    class BooleanExpression < ComplexExpression
      def self.from_msgpack_ext(data)
        MessagePack.unpack(data).tap { |h|
          return BooleanExpression.new(h[:op], *h[:args])
        }
      end

      def to_msgpack_ext
        { op: @op,
          args: @args
        }.to_msgpack
      end
    end

  end
end

MessagePack::DefaultFactory.register_type(0x00, Symbol)
MessagePack::DefaultFactory.register_type(0x01, Time)
MessagePack::DefaultFactory.register_type(0x02, Sequel::SQL::BooleanExpression)
