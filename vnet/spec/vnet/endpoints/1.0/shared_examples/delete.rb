# -*- coding: utf-8 -*-

shared_examples "a delete call" do
  before(:each) do
    delete api_suffix_with_uuid
  end

  context "with a nonexistant uuid" do
    let(:api_suffix_with_uuid) { "#{api_suffix}/#{model_class.uuid_prefix}-notfound" }

    it "should return a 404 error (UnknownUUIDResource)" do
      last_response.should fail.with_code(404).with_error("UnknownUUIDResource",
        "#{model_class.uuid_prefix}-notfound")
    end
  end

  context "with an existing uuid" do
    let!(:object) { Fabricate(fabricator) }
    let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}" }

    it "should delete one database entry" do
      last_response.should succeed.with_body([object.canonical_uuid])

      model_class[object.canonical_uuid].should eq(nil)
    end
  end
end
