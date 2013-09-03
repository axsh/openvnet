# -*- coding: utf-8 -*-

shared_examples "PUT /:uuid" do |uuid_params = []|
  before(:each) do
    put api_suffix_with_uuid, request_params
  end

  let(:request_params) { accepted_params }

  include_examples "api_with_uuid_in_suffix"

  context "with an existing uuid" do
    let!(:object) { Fabricate(fabricator) }
    let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}" }

    uuid_params.each { |up| include_examples "uuid_in_param", up }

    context "with the correct parameters" do
      it "should update the database entry" do
        last_response.should succeed.with_body_containing(
          accepted_params.merge({:uuid => object.canonical_uuid})
        )

        #TODO: Check the data in de database
      end
    end
  end
end
