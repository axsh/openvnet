module Vnet::Endpoints::V10::Responses
  class IpRetention < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpRetention)
      object.to_hash
    end
  end

  class IpRetentionCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| IpRetention.generate(i) }
    end
  end
end
