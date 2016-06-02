# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "wanedge" do
  it "reaches to 8.8.8.8" do
    expect(vm1).to be_able_to_ping("8.8.8.8")
  end
end
