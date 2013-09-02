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

shared_examples "a put call" do |suffix, uuid_prefix, fabricator, accepted_params|
  context "with a nonexistant uuid" do
    it "should return a 404 error" do
      put "/#{suffix}/#{uuid_prefix}-notfound"
      expect(last_response.status).to eq 404
    end
  end

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

shared_examples "a get call without uuid" do |suffix, fabricator|
  context "with no #{suffix} in the database" do
    it "should return empty json" do
      get "/#{suffix}"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body).to be_empty
    end
  end

  context "with 3 #{suffix} in the database" do
    before(:each) do
      3.times { Fabricate(fabricator) }
    end

    it "should return 3 #{suffix}" do
      get "/#{suffix}"

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body.size).to eq 3
    end
  end
end

shared_examples "a get call with uuid" do |suffix, uuid_prefix, fabricator|
  context "with a non existing uuid" do
    it "should return 404 error" do
      get "/#{suffix}/#{uuid_prefix}-notfound"
      expect(last_response).to be_not_found
    end
  end

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

shared_examples "a post call" do |suffix, accepted_params, required_params|
  context "without the uuid parameter" do
    it "should create a #{suffix.chomp("s")}" do
      params = accepted_params.dup
      params.delete(:uuid)
      post "/#{suffix}", params

      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      params.each { |k,v|
        expect(body[k.to_s]).to eq v
      }
    end
  end

  context "with the uuid parameter" do
    it "should create a #{suffix.chomp("s")} with the given uuid" do
      post "/#{suffix}", accepted_params
      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      accepted_params.each { |k,v|
        expect(body[k.to_s]).to eq v
      }
    end
  end

  context "with a uuid parameter with a faulty syntax" do
    it "should return a 400 error" do
      post "/#{suffix}", { :uuid => "this_aint_no_uuid" }
      expect(last_response.status).to eq 400
    end
  end

  required_params.each { |req_p|
    context "without the '#{req_p}' parameter" do
      it "should return a 400 error" do
        params = accepted_params.dup
        params.delete(req_p)
        post "/#{suffix}", params
        expect(last_response.status).to eq 400
      end
    end
  }
end
