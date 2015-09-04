# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "router_p2v" do
  describe "public to public" do
    context "vm1 to vm3" do
      it "reachable" do
        expect(vm1).to be_reachable_to(vm3)
      end
    end
    context "vm3 to vm1" do
      it "reachable" do
        expect(vm3).to be_reachable_to(vm1)
      end
    end
  end
  
  describe "public to 102" do
    describe "vm1 to vm2" do
      it "reachable" do
        expect(vm1).to be_reachable_to(vm2)
      end
    end
    describe "vm1 to vm4" do
      it "reachable" do
        expect(vm1).to be_reachable_to(vm4)
      end
    end
    describe "vm1 to vm6" do
      it "reachable" do
        expect(vm1).to be_reachable_to(vm6)
      end
    end
    describe "vm3 to vm2" do
      it "reachable" do
        expect(vm3).to be_reachable_to(vm2)
      end
    end
    describe "vm3 to vm4" do
      it "reachable" do
        expect(vm3).to be_reachable_to(vm4)
      end
    end
    describe "vm3 to vm6" do
      it "reachable" do
        expect(vm3).to be_reachable_to(vm6)
      end
    end
  end

  describe "public to 101" do
    describe "vm1 to vm5" do
      it "reachable" do
        expect(vm1).to be_reachable_to(vm5)
      end
    end
    describe "vm3 to vm5" do
      it "reachable" do
        expect(vm3).to be_reachable_to(vm5)
      end
    end
  end

  describe "102 to public" do
    describe "vm2 to vm1" do
      it "reachable" do
        expect(vm2).to be_reachable_to(vm1)
      end
    end
    describe "vm2 to vm3" do
      it "reachable" do
        expect(vm2).to be_reachable_to(vm3)
      end
    end
    describe "vm4 to vm1" do
      it "reachable" do
        expect(vm4).to be_reachable_to(vm1)
      end
    end
    describe "vm4 to vm3" do
      it "reachable" do
        expect(vm4).to be_reachable_to(vm3)
      end
    end
    describe "vm6 to vm1" do
      it "reachable" do
        expect(vm6).to be_reachable_to(vm1)
      end
    end
    describe "vm6 to vm3" do
      it "reachable" do
        expect(vm6).to be_reachable_to(vm3)
      end
    end
  end

  describe "102 to 102" do
    describe "vm2 to vm4" do
      it "reachable" do
        expect(vm2).to be_reachable_to(vm4)
      end
    end
    describe "vm2 to vm6" do
      it "reachable" do
        expect(vm2).to be_reachable_to(vm6)
      end
    end
    describe "vm4 to vm2" do
      it "reachable" do
        expect(vm4).to be_reachable_to(vm2)
      end
    end
    describe "vm4 to vm6" do
      it "reachable" do
        expect(vm4).to be_reachable_to(vm6)
      end
    end
    describe "vm6 to vm2" do
      it "reachable" do
        expect(vm6).to be_reachable_to(vm6)
      end
    end
    describe "vm6 to vm4" do
      it "reachable" do
        expect(vm6).to be_reachable_to(vm4)
      end
    end
  end

  describe "102 to 101" do
    describe "vm2 to vm5" do
      it "reachable" do
        expect(vm2).to be_reachable_to(vm5)
      end
    end
    describe "vm4 to vm5" do
      it "reachable" do
        expect(vm4).to be_reachable_to(vm5)
      end
    end
    describe "vm6 to vm5" do
      it "reachable" do
        expect(vm6).to be_reachable_to(vm5)
      end
    end
  end

  describe "101 to public" do
    describe "vm5 to vm1" do
      it "reachable" do
        expect(vm5).to be_reachable_to(vm1)
      end
    end
    describe "vm5 to vm3" do
      it "reachable" do
        expect(vm5).to be_reachable_to(vm3)
      end
    end
  end

  describe "101 to 102" do
    describe "vm5 to vm2" do
      it "reachable" do
        expect(vm5).to be_reachable_to(vm2)
      end
    end
    describe "vm5 to vm4" do
      it "reachable" do
        expect(vm5).to be_reachable_to(vm4)
      end
    end
    describe "vm5 to vm6" do
      it "reachable" do
        expect(vm5).to be_reachable_to(vm6)
      end
    end
  end
end
