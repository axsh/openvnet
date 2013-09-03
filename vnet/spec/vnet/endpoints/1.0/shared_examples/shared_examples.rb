# -*- coding: utf-8 -*-

def non_existant_uuid_404(suffix, uuid_prefix)
  context "with a nonexistant uuid" do
    expected_error = "UnknownUUIDResource"

    it "should return a 404 error (#{expected_error})" do
      faulty_uuid = "#{uuid_prefix}-notfound"

      delete "/#{suffix}/#{faulty_uuid}"
      expect(last_response.status).to eq 404
      check_error(last_response.body, "#{expected_error}", faulty_uuid)
    end
  end
end

def check_error(body, type, message)
  body = JSON.parse(last_response.body)
  expect(body["error"]).to eq "Vnet::Endpoints::Errors::#{type}"
  expect(body["message"]).to eq(message)
end

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

shared_examples "a get call without uuid" do# |suffix, fabricator|
  context "with no entries in the database" do
    it "should return empty json" do
      get "/#{@api_suffix}"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body).to be_empty
    end
  end

  context "with 3 entries in the database" do
    before(:each) do
      3.times { Fabricate(@fabricator) }
    end

    it "should return 3 entries" do
      get "/#{@api_suffix}"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body.size).to eq 3
    end
  end
end

shared_examples "a get call with uuid" do |suffix, uuid_prefix, fabricator|
  non_existant_uuid_404(suffix, uuid_prefix)

  context "with an existing uuid" do
    let!(:object) { Fabricate(fabricator) }

    it "should return a #{suffix.chomp("s")}" do
      get "/#{suffix}/#{object.canonical_uuid}"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body["uuid"]).to eq object.canonical_uuid
    end
  end
end
