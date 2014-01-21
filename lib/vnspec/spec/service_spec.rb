# -*- coding: utf-8 -*-

require_relative "spec_helper"

shared_examples_for "vm1(reachable)" do
  it "vm1 should reach vm3" do
    expect(vm1).to be_reachable_to(vm3, via: :name)
  end

  it "vm1 should reach vm5" do
    expect(vm1).to be_reachable_to(vm5, via: :name)
  end
end

shared_examples_for "vm1(unreachable)" do
  it "vm1 should not reach vm3" do
    expect(vm1).not_to be_reachable_to(vm3, via: :name)
  end

  it "vm1 should not reach vm5" do
    expect(vm1).not_to be_reachable_to(vm5, via: :name)
  end
end

describe "service" do
  before(:all) do
  end

  describe "dns" do
    describe "after booting vna with dns enabled" do
      include_examples "vm1(reachable)"
    end

    describe "after removing dns record 'vm1'" do
      before(:all) do
        dns_service = Vnspec::Models::DnsService.find("dnss-1")
        dns_service.remove_dns_record("dnsr-3")
        vm1.restart_network
      end

      it "vm1 should resolve google.com " do
        expect(vm1).to be_resolvable("google.com")
      end

      it "vm1 should not resolve vm3" do
        expect(vm1).not_to be_resolvable("vm3")
      end
    end

    describe "after removing dns service" do
      before(:all) do
        dns_service = Vnspec::Models::DnsService.find("dnss-1")
        dns_service.destroy
        vm1.restart_network
      end

      it "vm1 should not resolve google.com" do
        expect(vm1).not_to be_resolvable("google.com")
      end

      include_examples "vm1(unreachable)"
    end

    describe "after adding dns service" do
      before(:all) do
        Vnspec::Models::DnsService.create(
          uuid: "dnss-new1",
          network_service_uuid: "ns-dns1",
        )
        vm1.restart_network
      end

      it "vm1 should not resolve google.com " do
        expect(vm1).not_to be_resolvable("google.com")
      end
    end

    describe "after adding public_dns to dns service" do
      before(:all) do
        dns_service = Vnspec::Models::DnsService.find("dnss-new1")
        dns_service.update_public_dns("8.8.8.8")
        vm1.restart_network
      end

      it "vm1 should resolve google.com " do
        expect(vm1).to be_resolvable("google.com")
      end
    end


    describe "after adding dns record 'vm3'" do
      before(:all) do
        dns_service = Vnspec::Models::DnsService.find("dnss-new1")
        dns_service.add_dns_record(
          uuid: "dnsr-new1",
          name: "vm1",
          ipv4_address: "10.101.0.10"
        )
        dns_service.add_dns_record(
          uuid: "dnsr-new3",
          name: "vm3",
          ipv4_address: "10.101.0.11"
        )
        dns_service.add_dns_record(
          uuid: "dnsr-new5",
          name: "vm5",
          ipv4_address: "10.101.0.12"
        )
        vm1.restart_network
      end

      it "vm1 should resolve vm3" do
        expect(vm1).to be_resolvable("vm3")
      end
    end

    describe "after all dns data is set" do
      include_examples "vm1(reachable)"
    end
  end
end
