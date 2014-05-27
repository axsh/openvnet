require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/ip_lease_containers" do
  let(:api_suffix)  { "ip_lease_containers" }
  let(:fabricator)  { :ip_lease_container }
  let(:model_class) { Vnet::Models::IpLeaseContainer }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {}
    required_params = []
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end

  describe "PUT /:uuid" do
    accepted_params = {}

    include_examples "PUT /:uuid", accepted_params
  end
end
