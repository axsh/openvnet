# -*- coding: utf-8 -*-
require 'spec_helper'

module Vnmgr::Configurations
  class Test < Common
  end
end

describe Vnmgr::Configurations::Common do
  let(:config_path) { File.join(File.expand_path(File.dirname(__FILE__)), "config") }

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
    subject {  }
    it "load without filename" do
      expect(Vnmgr::Configurations::Common.load.redis_host).to eq "aaa.com"
    end

    it "load with filename" do
      expect(Vnmgr::Configurations::Common.load(File.join(config_path, "common2.conf")).redis_host).to eq "bbb.com"
    end

    it "config file not found" do
      expect { Vnmgr::Configurations::Test.load }.to raise_error
    end
  end

  describe "conf" do
    subject { Vnmgr::Configurations::Common.conf }
    it { expect(subject).to be_a Vnmgr::Configurations::Common }
    it { expect(subject.redis_host).to eq "aaa.com" }
  end
end
