# -*- coding: utf-8 -*-

shared_examples "one_to_many_relation_uuid_checks" do |relation_suffix, options|
  let(:relation_uuid_with_slash) { options[:with_relation_uuid] ? "/" + relation_uuid : "" }

  context "with a nonexistant uuid for the base object" do
    let(:api_relation_suffix) {
      "#{api_suffix}/#{model_class.uuid_prefix}-notfound/#{relation_suffix}#{relation_uuid_with_slash}"
    }

    it "should return a 404 error (UnknownUUIDResource)" do
      expect(last_response).to fail.with_code(404).with_error("UnknownUUIDResource",
        /#{model_class.uuid_prefix}-notfound$/)
    end
  end

  context "with faulty uuid syntax for the base object" do
    let(:api_relation_suffix) {
      "#{api_suffix}/this_is_not_an_uuid/#{relation_suffix}#{relation_uuid_with_slash}"
    }

    it_should_return_error(400, "InvalidUUID", /this_is_not_an_uuid$/)
  end
end

shared_examples "one_to_many_relation" do |relation_suffix, post_request_params|
  let!(:base_object) { Fabricate(fabricator) }
  let(:relation_uuid) { post_request_params[:uuid] }
  let(:relation_uuid_prefix) { relation_uuid.split("-").first }

  relation_uuid_label = ":#{relation_suffix.chomp("s")}_uuid"

  describe "POST /:uuid/#{relation_suffix}" do
    before(:each) do
      post api_relation_suffix, request_params
    end

    let(:request_params) { post_request_params }

    include_examples "one_to_many_relation_uuid_checks", relation_suffix, with_relation_uuid: false

    context "with faulty uuid syntax for the related object" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}"
      }

      let(:request_params) { post_request_params.merge(:uuid => "this_is_not_an_uuid") }

      it_should_return_error(400, "InvalidUUID", /this_is_not_an_uuid$/)
    end

    context "with a related object that isn't added to the base object yet" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}"
      }

      it "should create a new entry in the join table" do
        expect(last_response).to succeed
        expect(JSON.parse(last_response.body)["uuid"]).to eq relation_uuid
        expect(base_object.send(relation_suffix).size).to eq 1
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
        expect(last_response).to succeed.with_body({
          "total_count" => 0,
          "offset" =>  0,
          "limit" => Vnet::Configurations::Webapi.conf.pagination_limit,
          "items" => [],
        })

        expect(JSON.parse(last_response.body)["items"].size).to eq 0
      end
    end

    context "With 3 relations in the database" do
      let(:entries) { 3 }

      it "should return a json with 3 relations in it" do
        expect(last_response).to succeed.with_body_containing({
          "total_count" => 3,
          "offset" =>  0,
          "limit" => Vnet::Configurations::Webapi.conf.pagination_limit,
        })

        expect(JSON.parse(last_response.body)["items"].size).to eq 3
      end
    end
  end

  describe "DELETE /:uuid/#{relation_suffix}/#{relation_uuid_label}" do
    before(:each) do
      add_relation = "add_#{relation_suffix.singularize}"
      relation_object = Fabricate(relation_fabricator, uuid: relation_uuid.dup)
      base_object.send(add_relation, relation_object)

      delete api_relation_suffix, request_params
    end

    let(:request_params) { Hash.new }

    include_examples "one_to_many_relation_uuid_checks", relation_suffix, with_relation_uuid: true

    context "with a nonexistant uuid for the relation" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/#{relation_uuid_prefix}-notfound"
      }

      it "should return a 404 error (UnknownUUIDResource)" do
        expect(last_response).to fail.with_code(404).with_error("UnknownUUIDResource",
          /#{relation_uuid_prefix}-notfound$/)
      end
    end

    context "with faulty uuid syntax for the related object" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/this_is_not_an_uuid"
      }

      it_should_return_error(400, "InvalidUUID", /this_is_not_an_uuid$/)
    end

    context "with a related object that has already been added to the base object" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/#{relation_uuid}"
      }

      it "should destroy the entry in the join table" do
        expect(last_response).to succeed
        expect(base_object.send(relation_suffix)).to eq []
      end
    end
  end
end
