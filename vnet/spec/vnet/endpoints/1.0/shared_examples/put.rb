# -*- coding: utf-8 -*-

shared_examples "PUT /:uuid" do |accepted_params, uuid_params = []|
  before(:each) do
    put api_suffix_with_uuid, request_params
  end

  let(:request_params) { accepted_params }
  let!(:object) { Fabricate(fabricator) }
  let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}" }

  include_examples "api_with_uuid_in_suffix"

  context "with an existing uuid" do
    uuid_params.each { |up| include_examples "uuid_in_param", accepted_params, up }

    accepted_params.each { |k,v|
      context "with only the '#{k}' parameter" do
        let(:request_params) { { k => v } }

        it "only that parameter should be updated" do
          expect(last_response).to succeed.with_body_containing(request_params)
        end
      end
    }

    context "with all correct parameters" do
      it "should update all parameters" do
        expect(last_response).to succeed.with_body_containing(
          accepted_params.merge({:uuid => object.canonical_uuid})
        )
      end
    end
  end
end
