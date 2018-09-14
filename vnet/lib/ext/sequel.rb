# -*- coding: utf-8 -*-

require 'msgpack'

# class BooleanExpression
#   def self.from_msgpack_ext(data)
#     data.unpack('I*').tap { |s, n| at(s, Rational(n, 1000)) }
#   end

#   def to_msgpack_ext
#     [, tv_nsec].pack('I*')
#   end
# end

#MessagePack::DefaultFactory.register_type(0x10, Sequel::SQL::BooleanExpression)
MessagePack::DefaultFactory.register_type(0x10, Sequel::SQL::BooleanExpression, packer: :serialize, unpacker: :deserialize)
