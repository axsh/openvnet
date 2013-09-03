# -*- coding: utf-8 -*-

shared_examples "a post call" do | accepted_params, required_params|
  before(:each) { post "#{suffix}", request_params }

  context "without the uuid parameter" do
    let(:request_params) do
      accepted_params.dup.tap { |n|
        n.delete(:uuid)
      }
    end

    it "should create a database entry with a random uuid" do
      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      request_params.each { |k,v|
        expect(body[k.to_s]).to eq v
      }
    end
  end

  context "with the uuid parameter" do
    let(:request_params) { accepted_params }

    it "should create a database entry with the given uuid" do
      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      accepted_params.each { |k,v|
        expect(body[k.to_s]).to eq v
      }
    end
  end

  context "with a uuid parameter with a faulty syntax" do
    let(:request_params) do
      accepted_params.dup.tap { |n|
        n[:uuid] = "this_aint_no_uuid"
      }
    end

    it "should return a 400 error (InvalidUUID)" do
      expect(last_response.status).to eq 400
      check_error(last_response.body, "InvalidUUID", "this_aint_no_uuid")
    end
  end

  required_params.each { |req_p|
    context "without the '#{req_p}' parameter" do
      let(:request_params) do
        accepted_params.dup.tap { |n|
          n.delete(req_p)
        }
      end

      it "should return a 400 error (MissingArgument)" do
        expect(last_response.status).to eq 400
        check_error(last_response.body, "MissingArgument", req_p.to_s)
      end
    end
  }
end
