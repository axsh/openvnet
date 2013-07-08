# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnmgr::VNet::Openflow::CookieCategory do

  describe "initial state" do
    subject do
      Vnmgr::VNet::Openflow::CookieCategory.new(0x1001, 5)
    end

    it { expect(subject.prefix).to eq 0x1001 }
    it { expect(subject.bitshift).to eq 5 }
    it { expect(subject.next_cookie).to eq (0x20020) }
    it { expect(subject.range_above).to eq (0x20020...0x20040) }
    it { expect(subject.range_below).to eq (0x20020...0x20020) }
  end

  describe "first cookie (state)" do
    subject do
      category = Vnmgr::VNet::Openflow::CookieCategory.new(0x1001, 5)
      category.update_next_cookie(0x20020)
      category
    end

    it { expect(subject.prefix).to eq 0x1001 }
    it { expect(subject.bitshift).to eq 5 }
    it { expect(subject.next_cookie).to eq (0x20021) }
    it { expect(subject.range_above).to eq (0x20021...0x20040) }
    it { expect(subject.range_below).to eq (0x20020...0x20021) }
  end

  describe "last cookie (state)" do
    subject do
      category = Vnmgr::VNet::Openflow::CookieCategory.new(0x1001, 5)
      category.update_next_cookie(0x2003f)
      category
    end

    it { expect(subject.prefix).to eq 0x1001 }
    it { expect(subject.bitshift).to eq 5 }
    it { expect(subject.next_cookie).to eq (0x20020) }
    it { expect(subject.range_above).to eq (0x20020...0x20040) }
    it { expect(subject.range_below).to eq (0x20020...0x20020) }
  end

  describe "all cookies except the last (state)" do
    subject do
      category = Vnmgr::VNet::Openflow::CookieCategory.new(0x1001, 5)
      (0x20020...0x2003f).each { |cookie| category.update_next_cookie(cookie) }
      category
    end

    it { expect(subject.prefix).to eq 0x1001 }
    it { expect(subject.bitshift).to eq 5 }
    it { expect(subject.next_cookie).to eq (0x2003f) }
    it { expect(subject.range_above).to eq (0x2003f...0x20040) }
    it { expect(subject.range_below).to eq (0x20020...0x2003f) }
  end

  describe "all cookies except the first (state)" do
    subject do
      category = Vnmgr::VNet::Openflow::CookieCategory.new(0x1001, 5)
      (0x20021...0x20040).each { |cookie| category.update_next_cookie(cookie) }
      category
    end

    it { expect(subject.prefix).to eq 0x1001 }
    it { expect(subject.bitshift).to eq 5 }
    it { expect(subject.next_cookie).to eq (0x20020) }
    it { expect(subject.range_above).to eq (0x20020...0x20040) }
    it { expect(subject.range_below).to eq (0x20020...0x20020) }
  end

  describe "all cookies including last (state)" do
    subject do
      category = Vnmgr::VNet::Openflow::CookieCategory.new(0x1001, 5)
      (0x20020...0x20040).each { |cookie| category.update_next_cookie(cookie) }
      category
    end

    it { expect(subject.prefix).to eq 0x1001 }
    it { expect(subject.bitshift).to eq 5 }
    it { expect(subject.next_cookie).to eq (0x20020) }
    it { expect(subject.range_above).to eq (0x20020...0x20040) }
    it { expect(subject.range_below).to eq (0x20020...0x20020) }
  end

  describe "exhaust cookies (state)" do
    subject do
      category = Vnmgr::VNet::Openflow::CookieCategory.new(0x1001, 5)
      category.update_next_cookie(nil)
      category
    end

    it { expect(subject.prefix).to eq 0x1001 }
    it { expect(subject.bitshift).to eq 5 }
    it { expect(subject.next_cookie).to eq nil }
    it { expect(subject.range_above).to eq (0...0) }
    it { expect(subject.range_below).to eq (0...0) }
  end

  describe "regain cookies (state)" do
    subject do
      category = Vnmgr::VNet::Openflow::CookieCategory.new(0x1001, 5)
      category.update_next_cookie(nil)
      category.update_next_cookie(0x20030)
      category
    end

    it { expect(subject.prefix).to eq 0x1001 }
    it { expect(subject.bitshift).to eq 5 }
    it { expect(subject.next_cookie).to eq 0x20030 }
    it { expect(subject.range_above).to eq (0x20030...0x20040) }
    it { expect(subject.range_below).to eq (0x20020...0x20030) }
  end

end

describe Vnmgr::VNet::Openflow::CookieManager do

  describe "initial state" do
    subject do
      Vnmgr::VNet::Openflow::CookieManager.new
    end

    it { expect(subject.acquire(:foo)).to eq nil }
    it { expect(subject.acquire(:foo, :bar)).to eq nil }
    it { expect(subject.release(:foo, 0x1)).to eq nil }
  end

  describe "one category (initial state)" do
    subject do
      cm = Vnmgr::VNet::Openflow::CookieManager.new
      cm.create_category(:foo, 0x2, 48)
      cm
    end

    it { expect(subject.acquire(:foo)).to eq (0x2 << 48) }
    it { expect(subject.acquire(:foo, :bar)).to eq (0x2 << 48) }
    it { expect(subject.release(:foo, (0x2 << 48))).to eq nil }
  end

  describe "one category (first cookie)" do
    subject do
      cm = Vnmgr::VNet::Openflow::CookieManager.new
      cm.create_category(:foo, 0x2, 48)
      cm.acquire(:foo, :bar)
      cm
    end

    it { expect(subject.acquire(:foo)).to eq (0x2 << 48) + 1 }
    it { expect(subject.acquire(:foo, :bar)).to eq (0x2 << 48) + 1 }
    it { expect(subject.release(:foo, (0x2 << 48))).to eq :bar }
    it { expect(subject.release(:foo, (0x2 << 48) + 1)).to eq nil }
  end

end
