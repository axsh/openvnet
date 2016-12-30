# -*- coding: utf-8 -*-

shared_examples "relation_uuid_checks" do |relation_suffix|
  context "with a nonexistant uuid for the base object" do
    let(:api_relation_suffix) {
      "#{api_suffix}/#{model_class.uuid_prefix}-notfound/#{relation_suffix}/#{related_object.canonical_uuid}"
    }

    it "should return a 404 error (UnknownUUIDResource)" do
      expect(last_response).to fail.with_code(404).with_error("UnknownUUIDResource",
        /#{model_class.uuid_prefix}-notfound$/)
    end
  end

  context "with a nonexistant uuid for the relation" do
    let(:api_relation_suffix) {
      "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/#{related_object.uuid_prefix}-notfound"
    }

    it "should return a 404 error (UnknownUUIDResource)" do
      expect(last_response).to fail.with_code(404).with_error("UnknownUUIDResource",
        /#{related_object.uuid_prefix}-notfound$/)
    end
  end

  context "with faulty uuid syntax for the base object" do
    let(:api_relation_suffix) {
      "#{api_suffix}/this_is_not_an_uuid/#{relation_suffix}/#{related_object.canonical_uuid}"
    }

    it_should_return_error(400, "InvalidUUID", /this_is_not_an_uuid$/)
  end

  context "with faulty uuid syntax for the related object" do
    let(:api_relation_suffix) {
      "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/this_is_not_an_uuid"
    }

    it_should_return_error(400, "InvalidUUID", /this_is_not_an_uuid$/)
  end
end
