# -*- coding: utf-8 -*-

def it_should_return_error(code, name, message)
  it "should return a #{code} error (#{name})" do
    code = 500
    last_response.should fail.with_code(code).with_error(name, message)
  end
end

shared_examples "a post call" do | accepted_params, required_params|
  before(:each) { post "#{api_suffix}", request_params }

  context "with only the required parameters" do
    let(:request_params) do
      accepted_params.dup.tap { |n|
        n.delete_if { |k,v| !required_params.member?(k) }
      }
    end

    it "should create a database entry the required parameters set" do
      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      request_params.each { |k,v|
        expect(body[k.to_s]).to eq v
      }
    end
  end

  context "with all accepted parameters" do
    let(:request_params) { accepted_params }

    it "should create a database entry with all parameters set" do
      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      accepted_params.each { |k,v|
        expect(body[k.to_s]).to eq v
      }
    end
  end

  context "with a uuid parameter with a faulty syntax" do
    let(:request_params) do
      accepted_params.dup.tap { |n| n[:uuid] = "this_aint_no_uuid" }
    end

    it_should_return_error(400, "InvalidUUID", "this_aint_no_uuid")
  end

  required_params.each do |req_p|
    context "without the '#{req_p}' parameter" do
      let(:request_params) do
        accepted_params.dup.tap { |n| n.delete(req_p) }
      end

      it_should_return_error(400, "MissingArgument", req_p.to_s)
    end
  end
end
