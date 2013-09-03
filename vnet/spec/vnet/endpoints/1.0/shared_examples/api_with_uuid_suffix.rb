# -*- coding: utf-8 -*-

shared_examples "api_with_uuid_in_suffix" do
  context "with a nonexistant uuid" do
    let(:api_suffix_with_uuid) { "#{api_suffix}/#{model_class.uuid_prefix}-notfound" }

    it "should return a 404 error (UnknownUUIDResource)" do
      last_response.should fail.with_code(404).with_error("UnknownUUIDResource",
        "#{model_class.uuid_prefix}-notfound")
    end
  end
end
