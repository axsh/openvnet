# -*- coding: utf-8 -*-

def it_should_return_error(code, name, message = nil)
  it "should return a #{code} error (#{name})" do
    last_response.should fail.with_code(code).with_error(name, message)
  end
end
