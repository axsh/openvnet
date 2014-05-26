module Vnet::Endpoints::V10::Responses
  class IpRetentionContainer < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpRetentionContainer)
      object.to_hash
    end
  end

  class IpRetentionContainerCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| IpRetentionContainer.generate(i) }
    end
  end
end
