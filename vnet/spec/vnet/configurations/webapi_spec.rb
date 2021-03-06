# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Configurations::Webapi do
  let(:config_path) { File.join(Vnet::ROOT, "spec/config") }

  before do
    allow(Vnet::Configurations::Webapi).to receive(:paths).and_return([config_path])
  end

  describe "param" do
    subject { Vnet::Configurations::Webapi.load }
    it { expect(subject.node.id).to eq "webapi" }
    it { expect(subject.node.addr.protocol).to eq "tcp" }
    it { expect(subject.node.addr.host).to eq "127.0.0.1" }
    it { expect(subject.node.addr.port).to eq 19101 }
    it { expect(subject.node.addr_string).to eq "tcp://127.0.0.1:19101" }
  end
end
