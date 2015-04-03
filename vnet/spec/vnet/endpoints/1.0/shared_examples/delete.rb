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
        expect(last_response).to succeed.with_body([object.canonical_uuid])

        expect(model_class[object.canonical_uuid]).to eq(nil)
      end
    end
  end
end

shared_examples "DELETE /:uuid/postfix" do
  describe "DELETE /:uuid/postfix" do
    before(:each) do
      delete api_suffix_with_uuid
    end

    include_examples "api_with_uuid_in_suffix_and_has_postfix"

    context "with an existing uuid" do
      let!(:object) { Fabricate(fabricator) }
      let(:api_suffix_with_uuid) {
        postfix_fabricate
        "#{api_suffix}/#{object.canonical_uuid}/#{api_postfix}"
      }

      it "should delete one database entry" do
        expect(last_response).to succeed

        expect(postfix_model_class[postfix_parent_sym => object.id]).to eq(nil)
      end
    end
  end
end
