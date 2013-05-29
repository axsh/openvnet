# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnmgr::DataAccess do
  describe "get_proxy" do
    let(:conf) do
      double(:conf)
    end

    it "raise unknown proxy error" do
      conf.stub(:data_access_proxy).and_return(:aaa)
      expect { Vnmgr::DataAccess.get_proxy(conf) }.to raise_error "Unknown proxy: aaa"
    end

    it "return dba proxy" do
      conf.stub(:data_access_proxy).and_return(:dba)
      expect(Vnmgr::DataAccess.get_proxy(conf)).to be_a Vnmgr::DataAccess::DBAProxy
    end

    it "return direct proxy" do
      conf.stub(:data_access_proxy).and_return(:direct)
      expect(Vnmgr::DataAccess.get_proxy(conf)).to be_a Vnmgr::DataAccess::DirectProxy
    end
  end
end
