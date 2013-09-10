# -*- coding: utf-8 -*-

shared_examples "relation_uuid_checks" do |relation_suffix|
    context "with a nonexistant uuid for the base object" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{model_class.uuid_prefix}-notfound/#{relation_suffix}/#{related_object.canonical_uuid}"
      }

      it "should return a 404 error (UnknownUUIDResource)" do
        last_response.should fail.with_code(404).with_error("UnknownUUIDResource",
          "#{model_class.uuid_prefix}-notfound")
      end
    end

    context "with a nonexistant uuid for the relation" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/#{related_object.uuid_prefix}-notfound"
      }

      it "should return a 404 error (UnknownUUIDResource)" do
        last_response.should fail.with_code(404).with_error("UnknownUUIDResource",
          "#{related_object.uuid_prefix}-notfound")
      end
    end

    context "with faulty uuid syntax for the base object" do
      let(:api_relation_suffix) {
        "#{api_suffix}/this_is_not_an_uuid/#{relation_suffix}/#{related_object.canonical_uuid}"
      }

      it_should_return_error(400, "InvalidUUID", "this_is_not_an_uuid")
    end

    context "with faulty uuid syntax for the related object" do
      let(:api_relation_suffix) {
        "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/this_is_not_an_uuid"
      }

      it_should_return_error(400, "InvalidUUID", "this_is_not_an_uuid")
    end
end

## WARNING: This isn't finished and not usable yet as a real shared example
shared_examples "many_to_many_relation" do |relation_suffix|
  describe "Many to many relation calls for #{relation_suffix}" do
    let!(:base_object) { Fabricate(fabricator) }
    let!(:related_object) { Fabricate(:network) }

    describe "POST /:uuid/#{relation_suffix}/:network_uuid" do
      before(:each) do
        post api_relation_suffix, request_params
      end

      let(:request_params) { {:broadcast_mac_address => "02:00:00:cc:00:02"} }

      include_examples "relation_uuid_checks", relation_suffix

      context "with a related object that isn't added to the base object yet" do
        let(:api_relation_suffix) {
          "#{api_suffix}/#{base_object.canonical_uuid}/#{relation_suffix}/#{related_object.canonical_uuid}"
        }

        it "should succeed" do
          last_response.should succeed
        end
      end
    end

    describe "DELETE /:uuid/#{relation_suffix}/:network_uuid" do
      before(:each) do
        delete api_relation_suffix, request_params
      end

      let(:request_params) { Hash.new }

      include_examples "relation_uuid_checks", relation_suffix

    end
  end
end
