# -*- coding: utf-8 -*-

shared_examples "PUT /" do |accepted_params|
  before(:each) do
    put api_suffix_with_uuid, request_parameters
  end

  let(:request_parameters) { accepted_params }

  include_examples "api_with_uuid_in_suffix"

  context "with an existing uuid" do
    let!(:object) { Fabricate(fabricator) }
    let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}" }

    it "should update the database entry" do
      last_response.should succeed.with_body_containing(
        accepted_params.merge({:uuid => object.canonical_uuid})
      )

      #TODO: Check the data in de database
    end
  end
end
