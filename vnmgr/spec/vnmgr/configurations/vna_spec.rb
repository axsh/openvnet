# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnmgr::Configurations::Vna do
  let(:config_path) { File.join(Vnmgr::ROOT, "spec/config") }

  before do
    Vnmgr::Configurations::Vna.stub(:paths).and_return([config_path])
  end

  describe "param" do
    subject { Vnmgr::Configurations::Vna.load }
    it { expect(subject.node.id).to eq "vna" }
    it { expect(subject.node.addr.protocol).to eq "tcp" }
    it { expect(subject.node.addr.host).to eq "127.0.0.1" }
    it { expect(subject.node.addr.port).to eq 19103 }
    it { expect(subject.node.addr_string).to eq "tcp://127.0.0.1:19103" }

    it { expect(subject.dba_node_id).to eq "dba" }
    it { expect(subject.dba_actor_name).to eq "dba" }
    it { expect(subject.data_access_proxy).to eq :dba }
  end
end
