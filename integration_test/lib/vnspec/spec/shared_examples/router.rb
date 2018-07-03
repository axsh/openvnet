# -*- coding: utf-8 -*-

shared_examples 'router examples' do
  describe 'vnet1' do
    context 'mac2mac' do
      it 'reachable to vnet1' do
        expect(vm1).to be_reachable_to(vm3)
        expect(vm3).to be_reachable_to(vm1)
      end

      it 'reachable to vnet2' do
        expect(vm1).to be_reachable_to(vm2)
        expect(vm1).to be_reachable_to(vm4)
        expect(vm3).to be_reachable_to(vm2)
        expect(vm3).to be_reachable_to(vm4)
        expect(vm5).to be_reachable_to(vm6)
      end
    end

    context 'tunnel' do
      it 'reachable to vnet1' do
        expect(vm1).to be_reachable_to(vm5)
        expect(vm3).to be_reachable_to(vm5)
        expect(vm5).to be_reachable_to(vm1)
        expect(vm5).to be_reachable_to(vm3)
      end

      it 'reachable to vnet2' do
        expect(vm1).to be_reachable_to(vm6)
        expect(vm3).to be_reachable_to(vm6)
        expect(vm5).to be_reachable_to(vm2)
        expect(vm5).to be_reachable_to(vm4)
      end
    end
  end

  describe 'vnet2' do
    context 'mac2mac' do
      it 'reachable to vnet1' do
        expect(vm2).to be_reachable_to(vm1)
        expect(vm2).to be_reachable_to(vm1)
        expect(vm4).to be_reachable_to(vm3)
        expect(vm4).to be_reachable_to(vm3)
        expect(vm6).to be_reachable_to(vm5)
      end

      it 'reachable to vnet2' do
        expect(vm2).to be_reachable_to(vm4)
        expect(vm4).to be_reachable_to(vm2)
      end
    end

    context 'tunnel' do
      it 'reachable to vnet1' do
        expect(vm2).to be_reachable_to(vm5)
        expect(vm4).to be_reachable_to(vm5)
        expect(vm6).to be_reachable_to(vm1)
        expect(vm6).to be_reachable_to(vm3)
      end

      it 'reachable to vnet2' do
        expect(vm2).to be_reachable_to(vm6)
        expect(vm4).to be_reachable_to(vm6)
        expect(vm6).to be_reachable_to(vm2)
        expect(vm6).to be_reachable_to(vm4)
      end
    end
  end
end

shared_examples 'router p2v examples' do
  describe 'underlay' do
    it 'public reachable to public' do
      expect(vm1).to be_reachable_to(vm3)
      expect(vm3).to be_reachable_to(vm1)
      expect(vm1).to be_reachable_to(vm5)
      expect(vm5).to be_reachable_to(vm1)
      expect(vm3).to be_reachable_to(vm5)
      expect(vm5).to be_reachable_to(vm3)
    end

    it 'vnet reachable to vnet' do
      expect(vm2).to be_reachable_to(vm4)
      expect(vm4).to be_reachable_to(vm2)
      expect(vm2).to be_reachable_to(vm6)
      expect(vm6).to be_reachable_to(vm2)
      expect(vm4).to be_reachable_to(vm6)
      expect(vm6).to be_reachable_to(vm4)
    end
  end

  describe 'local' do
    it 'vnet reachable to public' do
      expect(vm1).to be_reachable_to(vm2)
      expect(vm2).to be_reachable_to(vm1)
    end
  end

  describe 'mac2mac' do
    it 'vnet reachable to public on different host' do
      expect(vm2).to be_reachable_to(vm3)
      expect(vm3).to be_reachable_to(vm2)
      expect(vm1).to be_reachable_to(vm4)
      expect(vm4).to be_reachable_to(vm1)
    end

    it 'vnet reachable to public on same host' do
      expect(vm3).to be_reachable_to(vm4)
      expect(vm4).to be_reachable_to(vm3)
    end
  end

  describe 'tunnel' do
    it 'reachable to public on different host' do
      expect(vm2).to be_reachable_to(vm5)
      expect(vm5).to be_reachable_to(vm2)
      expect(vm1).to be_reachable_to(vm6)
      expect(vm6).to be_reachable_to(vm1)
    end

    it 'reachable to public on same host' do
      expect(vm5).to be_reachable_to(vm6)
      expect(vm6).to be_reachable_to(vm5)
    end
  end

  describe 'tunnel+mac2mac' do
    it 'reachable to public on different host' do
      expect(vm3).to be_reachable_to(vm6)
      expect(vm6).to be_reachable_to(vm3)
      expect(vm4).to be_reachable_to(vm5)
      expect(vm5).to be_reachable_to(vm4)
    end
  end

end
