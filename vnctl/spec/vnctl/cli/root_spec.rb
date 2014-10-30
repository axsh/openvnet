# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnctl::Cli::Root do
  it "should display error message" do
    content = capture(:stderr) {
      expect {
        begin
          Vnctl::Cli::Root.start(%w[datapaths show])
        rescue Errno::ECONNREFUSED => e
          abort("Network Error: " + e.to_s)
        end
      }.to raise_error SystemExit
    }
    expect(content).to eq "Network Error: Connection refused - connect(2) for \"127.0.0.1\" port 9090\n"
  end
end
