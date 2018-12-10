# -*- coding: utf-8 -*-

shared_examples "fails without the required parameters" do |accepted_params, required_params|
  required_params.each do |req_p|
    context "without the '#{req_p}' parameter" do
      let(:request_params) do
        accepted_params.dup.tap { |n| n.delete(req_p) }
      end

      it_should_return_error(400, "MissingArgument", req_p.to_s)
    end
  end
end

shared_examples "succeed with the required parameters" do |accepted_params, required_params|
  let(:request_params) do
    accepted_params.dup.tap { |n|
      n.delete_if { |k,v| !required_params.member?(k) }
    }
  end

  it "should create a database entry the required parameters set #{required_params}" do
    expect(last_response).to succeed.with_body_containing(request_params)
  end
end

shared_examples "POST /" do |accepted_params, required_params, uuid_params = [], expected_response = nil, success_proc = nil|
  expected_response ||= accepted_params

  exclusive_params = []
  required_params.delete_if { |k, v|
    v.kind_of?(Array) ? (exclusive_params << v) : nil
  }

  before(:each) { post api_suffix, request_params }

  context "with only the required parameters" do
    all_permutations(exclusive_params) { |expected|
      include_examples "succeed with the required parameters", accepted_params, (required_params + expected).uniq
    }
  end

  context "with all accepted parameters" do
    let(:request_params) { accepted_params }

    it "should create a database entry" do
      expect(last_response).to succeed.with_body_containing(expected_response)
    end

    it "should be able to recreate a taggable database entry" do
      next if !model_class.taggable?

      expect(request_params[:uuid]).not_to be_nil
      expect(last_response).to succeed.with_body_containing(expected_response)

      delete "#{api_suffix}/#{request_params[:uuid]}"

      post api_suffix, request_params

      expect(last_response).to succeed.with_body_containing(expected_response)

      model_class[request_params[:uuid]].tap { |model|
        expect(model).to be
        expect(success_proc.call(model, last_response)).to be if success_proc
      }
    end
  end

  uuid_params.each { |up| include_examples "uuid_in_param", accepted_params, up }

  all_permutations(exclusive_params) { |expected|
    include_examples "fails without the required parameters", accepted_params, (required_params + expected).uniq
  }
end
