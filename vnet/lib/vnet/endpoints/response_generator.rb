# -*- coding: utf-8 -*-

module Vnet::Endpoints
  class ResponseGenerator
    def self.generate(record)
      raise NotImplementedError
    end
  end

  class CollectionResponseGenerator < ResponseGenerator
    def self.generate_with_pagination(pagination, items)
      pagination.tap do |pag|
        pag[:items] = generate(items)
      end
    end

    def self.generate(items)
      raise NotImplementedError
    end
  end
end
