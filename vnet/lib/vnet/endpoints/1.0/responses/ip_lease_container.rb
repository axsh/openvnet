module Vnet::Endpoints::V10::Responses
  class IpLeaseContainer < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(object)
      argument_type_check(object,Vnet::ModelWrappers::IpLeaseContainer)
      object.to_hash
    end
  end

  class IpLeaseContainerCollection < Vnet::Endpoints::CollectionResponseGenerator
    def self.generate(array)
      argument_type_check(array,Array)
      array.map { |i| IpLeaseContainer.generate(i) }
    end
  end
end
