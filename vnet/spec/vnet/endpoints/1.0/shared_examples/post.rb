# -*- coding: utf-8 -*-

shared_examples "POST /" do | accepted_params, required_params|
  before(:each) { post api_suffix, request_params }

  context "with only the required parameters" do
    let(:request_params) do
      accepted_params.dup.tap { |n|
        n.delete_if { |k,v| !required_params.member?(k) }
      }
    end

    it "should create a database entry the required parameters set" do
      last_response.should succeed.with_body_containing(request_params)
      #TODO: Check actual database records
    end
  end

  context "with all accepted parameters" do
    let(:request_params) { accepted_params }

    it "should create a database entry with all parameters set" do
      last_response.should succeed.with_body_containing(accepted_params)
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
