# -*- coding: utf-8 -*-

shared_examples "PUT /:uuid/postfix" do |accepted_params, required_params, uuid_params = [], expected_response = nil|
  expected_response ||= accepted_params

  before(:each) do
    put api_suffix_with_uuid, request_params
  end

  let(:request_params) { accepted_params }
  let!(:object) { Fabricate(fabricator) }
  let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}/#{api_postfix}" }

  include_examples "api_with_uuid_in_suffix_and_has_postfix"

  context "with an existing uuid" do
    uuid_params.each { |up| include_examples "uuid_in_param", accepted_params, up }

    context "with only the required parameters" do
      let(:request_params) do
        accepted_params.dup.tap { |n|
          n.delete_if { |k,v| !required_params.member?(k) }
        }
      end

      it "should create a database entry the required parameters set" do
        expect(last_response).to succeed.with_body_containing(request_params)
      end
    end

    context "with all accepted parameters" do
      let(:request_params) { accepted_params }

      it "should create a database entry with all parameters set" do
        expect(last_response).to succeed.with_body_containing(expected_response)
      end
    end

  end
end


# shared_examples "PUT /:uuid/postfix/:postfix_uuid" do |accepted_params, required_params, uuid_params = [], expected_response = nil|
#   expected_response ||= accepted_params

#   before(:each) do
#     put api_suffix_with_uuid, request_params
#   end

#   let(:request_params) { accepted_params }
#   let!(:object) { Fabricate(fabricator) }
#   let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}/#{api_postfix}" }

#   include_examples "api_with_uuid_in_suffix_and_has_postfix"

#   context "with an existing uuid" do
#     uuid_params.each { |up| include_examples "uuid_in_param", accepted_params, up }

#     context "with only the required parameters" do
#       let(:request_params) do
#         accepted_params.dup.tap { |n|
#           n.delete_if { |k,v| !required_params.member?(k) }
#         }
#       end

#       it "should create a database entry the required parameters set" do
#         expect(last_response).to succeed.with_body_containing(request_params)
#       end
#     end

#     context "with all accepted parameters" do
#       let(:request_params) { accepted_params }

#       it "should create a database entry with all parameters set" do
#         expect(last_response).to succeed.with_body_containing(expected_response)
#       end
#     end

#   end
# end
