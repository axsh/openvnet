# -*- coding: utf-8 -*-

def it_should_return_error(code, name, message)
  it "should return a #{code} error (#{name})" do
    last_response.should fail.with_code(code).with_error(name, message)
  end
end

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

# def check_error(body, type, message)
#   body = JSON.parse(last_response.body)
#   expect(body["error"]).to eq "Vnet::Endpoints::Errors::#{type}"
#   expect(body["message"]).to eq(message)
# end
