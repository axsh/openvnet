# -*- coding: utf-8 -*-

def describe_standard_get
  describe "GET /" do
    include_examples "a get call without uuid"
  end

  describe "GET /:uuid" do
    include_examples "a get call with uuid"
  end
end

def describe_standard_delete
  describe "DELETE /:uuid" do
    include_examples "a delete call"
  end
end

def it_should_return_error(code, name, message)
  it "should return a #{code} error (#{name})" do
    last_response.should fail.with_code(code).with_error(name, message)
  end
end
