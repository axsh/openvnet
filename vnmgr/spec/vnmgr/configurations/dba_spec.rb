# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnmgr::Configurations::Dba do
  let(:config_path) { File.join(Vnmgr::ROOT, "spec/config") }

  before do
    Vnmgr::Configurations::Dba.stub(:paths).and_return([config_path])
  end

  describe "param" do
    subject { Vnmgr::Configurations::Dba.load }
    it { expect(subject.node.id).to eq "dba" }
    it { expect(subject.node.addr.protocol).to eq "tcp" }
    it { expect(subject.node.addr.host).to eq "127.0.0.1" }
    it { expect(subject.node.addr.port).to eq 19102 }
    it { expect(subject.node.addr_string).to eq "tcp://127.0.0.1:19102" }

    it { expect(subject.actor_names).to eq ["dba"] }
  end
end
