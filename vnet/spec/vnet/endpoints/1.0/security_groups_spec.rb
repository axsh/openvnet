# -*- coding: utf-8 -*-
require 'spec_helper'
require 'vnet'
Dir["#{File.dirname(__FILE__)}/shared_examples/*.rb"].map {|f| require f }
Dir["#{File.dirname(__FILE__)}/matchers/*.rb"].map {|f| require f }

def app
  Vnet::Endpoints::V10::VnetAPI
end

describe "/security_groups" do
  let(:api_suffix)  { "security_groups" }
  let(:fabricator)  { :security_group }
  let(:model_class) { Vnet::Models::SecurityGroup}

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :uuid => "sg-test",
      :display_name => "our test secg",
      :description => "A longer description... or it should be at least."
    }
    required_params = [:display_name]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params
  end
end
