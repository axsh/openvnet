# -*- coding: utf-8 -*-
require 'spec_helper'

module Vnmgr::Configurations
  class Test < Common
  end
end

describe Vnmgr::Configurations::Common do
  let(:config_path) { File.join(Vnmgr::ROOT, "spec/config") }

  before do
    Vnmgr::Configurations::Common.stub(:paths).and_return([config_path])
  end

  describe "file_names" do
    it "return a file name" do
      expect(Vnmgr::Configurations::Common.file_names).to eq ["common.conf"]
    end

    it "return two file names" do
      expect(Vnmgr::Configurations::Vnmgr.file_names).to eq ["common.conf", "vnmgr.conf"]
    end
  end

  describe "load" do
    it "load without filename" do
      expect(Vnmgr::Configurations::Common.load.db.adapter).to eq "mysql2"
    end

    it "load with filename" do
      expect(Vnmgr::Configurations::Common.load(File.join(config_path, "common2.conf")).db.adapter).to eq "mysql"
    end

    it "config file not found" do
      expect { Vnmgr::Configurations::Test.load }.to raise_error
    end
  end

  describe "conf" do
    subject { Vnmgr::Configurations::Common.conf }
    it { expect(subject).to be_a Vnmgr::Configurations::Common }
    it { expect(subject.db.adapter).to eq "mysql2" }
  end

  describe "param" do
    subject { Vnmgr::Configurations::Common.load }
    it { expect(subject.registry.adapter).to eq "redis" }
    it { expect(subject.registry.host).to eq "127.0.0.1" }
    it { expect(subject.registry.port).to eq 6379 }
    it { expect(subject.db.adapter).to eq "mysql2" }
    it { expect(subject.db.database).to eq "vnmgr_test" }
    it { expect(subject.db.host).to eq "localhost" }
    it { expect(subject.db.port).to eq 3306 }
    it { expect(subject.db.user).to eq "root" }
    it { expect(subject.db.password).to eq "" }
    it { expect(subject.db_uri).to eq "mysql2://localhost:3306/vnmgr_test?user=root&password=" }
  end
end
