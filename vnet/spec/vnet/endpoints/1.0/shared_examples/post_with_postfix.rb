# -*- coding: utf-8 -*-

# shared_examples "required parameters" do |accepted_params, required_params|
#   required_params.each do |req_p|
#     context "without the '#{req_p}' parameter" do
#       let(:request_params) do
#         accepted_params.dup.tap { |n| n.delete(req_p) }
#       end

#       it_should_return_error(400, "MissingArgument", req_p.to_s)
#     end
#   end
# end

# shared_examples "POST /" do | accepted_params, required_params, uuid_params = [], expected_response = nil |
#   expected_response ||= accepted_params
#   before(:each) { post api_suffix, request_params }

#   context "with only the required parameters" do
#     let(:request_params) do
#       accepted_params.dup.tap { |n|
#         n.delete_if { |k,v| !required_params.member?(k) }
#       }
#     end

#     it "should create a database entry the required parameters set" do
#       expect(last_response).to succeed.with_body_containing(request_params)
#     end
#   end

#   context "with all accepted parameters" do
#     let(:request_params) { accepted_params }

#     it "should create a database entry with all parameters set" do
#       expect(last_response).to succeed.with_body_containing(expected_response)
#     end
#   end

#   uuid_params.each { |up| include_examples "uuid_in_param", accepted_params, up }

#   include_examples "required parameters", accepted_params, required_params
# end

shared_examples "POST /:uuid/postfix" do |accepted_params, required_params, uuid_params = [], expected_response = nil|
  expected_response ||= accepted_params

  before(:each) do
    post api_suffix_with_uuid, request_params
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
