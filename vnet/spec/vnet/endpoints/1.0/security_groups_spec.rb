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
  let(:model_class) { Vnet::Models::SecurityGroup }

  include_examples "GET /"
  include_examples "GET /:uuid"
  include_examples "DELETE /:uuid"

  describe "POST /" do
    accepted_params = {
      :uuid => "sg-test",
      :display_name => "our test secg",
      :description => "A longer description... or it should be at least.",
      :rules => "
        tcp:22:0.0.0.0
        udp:53:0.0.0.0
      "
    }
    required_params = [:display_name]
    uuid_params = [:uuid]

    include_examples "POST /", accepted_params, required_params, uuid_params

    context "with an existing security group uuid in the rules" do
      let(:group) { Fabricate(:security_group) }
      let(:request_params) { accepted_params.merge(rules: "icmp::#{group.canonical_uuid}") }

       it "should successfully create a security group referencing it" do
        expect(last_response).to succeed.with_body_containing(request_params)
      end
    end

    context "with a faulty protocol in the rules" do
      let(:request_params) { accepted_params.merge(rules: "broken") }

      it_should_return_error(
         500,
        "Sequel::ValidationFailed",
        "invalid protocol in rule 'broken'"
      )
    end

    context "with a faulty port in the rules" do
      let(:request_params) { accepted_params.merge(rules: "tcp:joske:0.0.0.0/0") }

      it_should_return_error(
        500,
        "Sequel::ValidationFailed",
        "invalid port in rule 'tcp:joske:0.0.0.0/0'"
      )
    end

    context "with a faulty ip in the rules" do
      let(:request_params) { accepted_params.merge(rules: "tcp:22:456.462.890.1/33") }

      it_should_return_error(
        500,
        "Sequel::ValidationFailed",
        "invalid ipv4 address or security group uuid in rule 'tcp:22:456.462.890.1/33'"
      )
    end

    context "with a faulty security group uuid in the rules" do
      let(:request_params) { accepted_params.merge(rules: "tcp:22:sg-i'm_illegal") }

      it_should_return_error(
        500,
        "Sequel::ValidationFailed",
        "invalid ipv4 address or security group uuid in rule 'tcp:22:sg-i'm_illegal'"
      )
    end

    context "with a correct but non existant security group uuid in the rules" do
      let(:request_params) { accepted_params.merge(rules: "tcp:22:sg-noexists") }

      it_should_return_error(
        500,
        "Sequel::ValidationFailed",
        "Unknown security group uuid in rule 'tcp:22:sg-noexists'"
      )
    end
  end
end
