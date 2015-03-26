# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnctl::Cli::Root do
  it "should display error message" do
    content = capture(:stderr) {
      expect { Vnctl::run(%w[datapaths show]) }.to raise_error SystemExit
    }
    expect(content).to eq "Network Error: Connection refused - connect(2) for \"127.0.0.1\" port 9123\n"
  end
end
