# -*- coding: utf-8 -*-

module Vnmgr::Endpoints
  module Errors
    class APIError < StandardError

      # HTTP status code of the error.
      def self.status_code(code=nil)
        if code
          @status_code = code
        end
        @status_code || raise("@status_code for the class is not set")
      end

      # Internal error code of the error.
      def self.error_code(code=nil)
        if code
          @error_code = code
        end
        @error_code || raise("@error_code for the class is not set")
      end

      def status_code
        self.class.status_code
      end
      # Sinatra reads http code from this method.
      alias :code :status_code
      alias :http_status :status_code

      def error_code
        self.class.error_code
      end
    end

    class DeprecatedAPIError < APIError
    end
  end

  def self.define_error(class_name, status_code, error_code, &blk)
    c = Class.new(Errors::APIError)
    c.status_code(status_code)
    c.error_code(error_code)
    c.instance_eval(&blk) if blk
    self.set_error_code_type(error_code, c)
    self.const_set(class_name.to_sym, c)
    Errors.const_set(class_name.to_sym, c)
  end

  def self.deprecated_error(class_name, status_code, error_code, &blk)
    c = Class.new(Errors::DeprecatedAPIError)
    c.status_code(status_code)
    c.error_code(error_code)
    c.instance_eval(&blk) if blk
    self.set_error_code_type(error_code, c)
    self.const_set(class_name.to_sym, c)
    Errors.const_set(class_name.to_sym, c)
  end

  @error_code_map = {}
  def self.set_error_code_type(error_code, klass)
    raise TypeError unless klass < Errors::APIError
    if @error_code_map.has_key?(error_code)
      if @error_code[error_code] == klass
      else
        raise "Duplicate Error Code Registration: #{klass}, code=#{error_code}"
      end
    else
      @error_code_map[error_code]=klass
    end
  end

  define_error(:UnknownUUIDResource, 404, '100')
  define_error(:InvalidUUID,400,'101')
  define_error(:DuplicateUUID,400,'102')

  define_error(:ArgumentError,400,'103')
  define_error(:MissingArgument,400,'104')

end
