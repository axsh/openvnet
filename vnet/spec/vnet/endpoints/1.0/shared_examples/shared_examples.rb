# -*- coding: utf-8 -*-

shared_examples "a delete call" do |suffix, uuid_prefix, fabricator, model_class|
    non_existant_uuid_404(suffix, uuid_prefix)

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

shared_examples "a put call" do |suffix, uuid_prefix, fabricator, accepted_params|
  non_existant_uuid_404(suffix, uuid_prefix)

  context "with an existing uuid" do
    let!(:object) { Fabricate(fabricator) }
    it "should update the database entry" do
      put "/#{suffix}/#{object.canonical_uuid}", accepted_params

      expect(last_response).to be_ok

      body = JSON.parse(last_response.body)
      expect(body["uuid"]).to eq object.canonical_uuid
      accepted_params.each { |k, v|
        expect(body[k.to_s]).to eq v
      }

      #TODO: Check the data in de database
    end
  end
end
