# -*- coding: utf-8 -*-
require 'spec_helper'

module Vnet::Configurations
  class Test < Common
  end
end

describe Vnet::Configurations::Common do
  let(:config_path) { File.join(Vnet::ROOT, "spec/config") }

  before do
    allow(Vnet::Configurations::Common).to receive(:paths).and_return([config_path])
  end

  describe "file_names" do
    it "return a file name" do
      expect(Vnet::Configurations::Common.file_names).to eq ["common.conf"]
    end

    it "return two file names" do
      expect(Vnet::Configurations::Vnmgr.file_names).to eq ["common.conf", "vnmgr.conf"]
    end
  end

  describe "load" do
    it "load without filename" do
      expect(Vnet::Configurations::Common.load.db.adapter).to eq "mysql2"
    end

    it "load with filename" do
      expect(Vnet::Configurations::Common.load(File.join(config_path, "common2.conf")).db.adapter).to eq "mysql"
    end

    it "config file not found" do
      expect { Vnet::Configurations::Test.load }.to raise_error
    end
  end

  describe "conf" do
    subject { Vnet::Configurations::Common.conf }
    it { expect(subject).to be_a Vnet::Configurations::Common }
    it { expect(subject.db.adapter).to eq "mysql2" }
  end

  describe "param" do
    subject { Vnet::Configurations::Common.load }
    it { expect(subject.registry.adapter).to eq "redis" }
    it { expect(subject.registry.host).to eq "127.0.0.1" }
    it { expect(subject.registry.port).to eq 6379 }
    it { expect(subject.db.adapter).to eq "mysql2" }
    it { expect(subject.db.database).to eq "vnet_test" }
    it { expect(subject.db.host).to eq "localhost" }
    it { expect(subject.db.port).to eq 3306 }
    it { expect(subject.db.user).to eq "root" }
    it { expect(subject.db.password).to eq "" }
    it { expect(subject.db_uri).to eq "mysql2://localhost:3306/vnet_test?user=root&password=" }
  end
end
