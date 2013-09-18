# -*- coding: utf-8 -*-

shared_examples "uuid_in_param" do |accepted_params, uuid_param|
  context "with a '#{uuid_param}' with a faulty syntax" do
    let(:request_params) { accepted_params.dup.tap {|n| n[uuid_param] = "faulty_uuid"} }

    it_should_return_error(400, "InvalidUUID", /faulty_uuid$/)
  end
end
