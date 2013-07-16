# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnet::Configurations::Webapi do
  let(:config_path) { File.join(Vnet::ROOT, "spec/config") }

  before do
    Vnet::Configurations::Webapi.stub(:paths).and_return([config_path])
  end

  describe "param" do
    subject { Vnet::Configurations::Webapi.load }
    it { expect(subject.node.id).to eq "webapi" }
    it { expect(subject.node.addr.protocol).to eq "tcp" }
    it { expect(subject.node.addr.host).to eq "127.0.0.1" }
    it { expect(subject.node.addr.port).to eq 19101 }
    it { expect(subject.node.addr_string).to eq "tcp://127.0.0.1:19101" }

    it { expect(subject.rpc_node_id).to eq "vnmgr" }
    it { expect(subject.rpc_actor_name).to eq "rpc" }
    it { expect(subject.node_api_proxy).to eq :direct }
  end
end
