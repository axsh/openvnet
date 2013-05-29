# -*- coding: utf-8 -*-
module Vnmgr::DataAccess::Models
  class Base
    attr_accessor :model_class
    def initialize
      @model_class = Vnmgr::Models.const_get(self.class.name.demodulize)
    end

    def destroy(uuid = nil)
      Sequel::DATABASES.first.transaction do
        if uuid
          model = model_class[uuid]
          # TODO define error class
          raise "model not found. uuid: #{uuid}" unless model
          model.destroy.to_hash
        else
          # call original model method
          model_class.destroy
        end
      end
    end

    def update(uuid, options = {})
      Sequel::DATABASES.first.transaction do
        model = model_class[uuid]
        # TODO define error class
        raise "model not found. uuid: #{uuid}" unless model
        # return old model if no attribute is updated
        (model.update(options) || model).to_hash
      end
    end

    def method_missing(method_name, *args, &block)
      if model_class.respond_to?(method_name)
        define_singleton_method(method_name) do |*args|
          # TODO db transaction
          Sequel::DATABASES.first.transaction do
            to_hash(model_class.send(method_name, *args, &block))
          end
        end
        self.send(method_name, *args, &block)
      else
        super
      end
    end

    def to_hash(data)
      case data
      when Array
        data.map { |d|
          d.to_hash
        }
      when Vnmgr::Models::Base
        data.to_hash
      when nil
        nil
      else
        raise ArgumentError, "Unexpected data type: #{data.class}"
      end
    end
  end
end
