# -*- coding: utf-8 -*-

shared_examples "relation_uuid_checks" do |relation_suffix, relation_uuid_label|
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

shared_examples "many_to_many_relation" do |relation_suffix, post_request_params|
  let!(:base_object) { Fabricate(fabricator) }
  let!(:related_object) { Fabricate(relation_fabricator) }

  relation_uuid_label = ":#{relation_suffix.chomp("s")}_uuid"

  describe "POST /:uuid/#{relation_suffix}/#{relation_uuid_label}" do
    before(:each) do
      post api_relation_suffix, request_params
    end

    let(:request_params) { post_request_params }

    include_examples "relation_uuid_checks", relation_suffix

    context "with a related object that isn't added to the base object yet" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/#{related_object.canonical_uuid}"
      }

      it "should create a new entry in the join table" do
        expect(last_response).to succeed
        expect(base_object.send(relation_suffix)).to eq [related_object]
      end
    end
  end

  describe "GET /:uuid/#{relation_suffix}" do
    before(:each) do
      add_relation = "add_#{relation_suffix.chomp("s")}"
      entries.times {
        base_object.send(add_relation, Fabricate(relation_fabricator))
      }

      get api_relation_suffix
    end

    let(:api_relation_suffix) {
      "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}"
    }

    context "With no relations in the database" do
      let(:entries) { 0 }

      it "should return a json with empty relations" do
        expect(last_response).to succeed.with_body([])

        expect(JSON.parse(last_response.body).size).to eq 0
      end
    end

    context "With 3 relations in the database" do
      let(:entries) { 3 }

      it "should return a json with 3 relations in it" do
        expect(JSON.parse(last_response.body).size).to eq 3
      end
    end
  end

  describe "DELETE /:uuid/#{relation_suffix}/#{relation_uuid_label}" do
    before(:each) do
      delete api_relation_suffix, request_params
    end

    let(:request_params) { Hash.new }

    include_examples "relation_uuid_checks", relation_suffix, relation_uuid_label
  end
end
