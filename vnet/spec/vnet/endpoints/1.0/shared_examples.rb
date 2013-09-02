# -*- coding: utf-8 -*-

shared_examples "a delete call" do |suffix, uuid_prefix, fabricator, model_class|
    context "with a nonexistant uuid" do
      it "should return a 404 error" do
        delete "/#{suffix}/#{uuid_prefix}-notfound"
        expect(last_response.status).to eq 404
      end
    end

    context "with an existing uuid" do
      let!(:object) { Fabricate(fabricator) }
      it "should delete the datapath" do
        delete "/#{suffix}/#{object.canonical_uuid}"

        expect(last_response).to be_ok
        body = JSON.parse(last_response.body)
        expect(body.first).to eq object.canonical_uuid

        Vnet::Models.const_get(model_class)[object.canonical_uuid].should eq(nil)
      end
    end
end

shared_examples "a put call" do |suffix, uuid_prefix, fabricator, request_params, expected_response|
  context "with a nonexistant uuid" do
    it "should return a 404 error" do
      put "/#{suffix}/#{uuid_prefix}-notfound"
      expect(last_response.status).to eq 404
    end
  end

  context "with an existing uuid" do
    let!(:object) { Fabricate(fabricator) }
    it "should update the database entry" do
      put "/#{suffix}/#{object.canonical_uuid}", request_params
      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body["uuid"]).to eq object.canonical_uuid
      expected_response.each { |k, v|
        expect(body[k]).to eq v
      }

      #TODO: Check the data in de database
    end
  end
end
