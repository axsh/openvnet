# -*- coding: utf-8 -*-

shared_examples "DELETE /:uuid" do
  describe "DELETE /:uuid" do
    before(:each) do
      delete api_suffix_with_uuid
    end

    include_examples "api_with_uuid_in_suffix"

    context "with an existing uuid" do
      let!(:object) { Fabricate(fabricator) }
      let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}" }

      it "should delete one database entry" do
        last_response.should succeed.with_body([object.canonical_uuid])

        model_class[object.canonical_uuid].should eq(nil)
      end
    end
  end
end
