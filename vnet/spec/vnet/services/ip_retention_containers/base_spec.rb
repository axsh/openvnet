require 'spec_helper'

describe Vnet::Services::IpRetentionContainers::Base do
  let(:instance) do
    described_class.new(id: 1, lease_time: 1000, grace_time: 1000).tap(&:try_install)
  end

  let(:current_time) { Time.now }

  describe ".add_ip_retention" do
    context "without lease_time_expired_at" do
      subject do
        instance.add_ip_retention(id: 1, ip_lease_id: 1)
        instance
      end

      it { expect(subject.ip_retentions.size).to eq 1 }
      it { expect(subject.lease_time_ip_retentions.size).to eq 0 }
    end

    context "with lease_time_expired_at" do
      subject do
        instance.add_ip_retention(id: 1, ip_lease_id: 1, lease_time_expired_at: current_time + 1000)
        instance
      end

      it { expect(subject.ip_retentions.size).to eq 1 }
      it { expect(subject.lease_time_ip_retentions.size).to eq 1 }
    end
  end

  describe ".remove_ip_retention" do
    before do
      instance.add_ip_retention(id: 1, ip_lease_id: 1, lease_time_expired_at: current_time + 1000)
    end

    subject do
      instance.remove_ip_retention(1)
      instance
    end

    it { expect(subject.ip_retentions.size).to eq 0 }
    it { expect(subject.lease_time_ip_retentions.size).to eq 0 }
  end

  describe ".expire_ip_retentions" do
    before do
      instance.add_ip_retention(id: 1, ip_lease_id: 1, lease_time_expired_at: current_time)
    end

    subject do
      allow(Vnet::ModelWrappers::IpLease).to receive(:expire).with(1)
      instance.expire_ip_retentions([1])
      instance
    end

    it { expect(subject.ip_retentions.size).to eq 1 }
    it { expect(subject.lease_time_ip_retentions.size).to eq 0 }
    it { expect(subject.grace_time_ip_retentions.size).to eq 1 }
  end

  describe ".check_lease_time_expiration" do
    it "expires ip_retentions whose lease time is expired" do

      allow(Time).to receive(:now).exactly(2).times.and_return(current_time)
      instance.add_ip_retention(id: 1, ip_lease_id: 1, lease_time_expired_at: current_time + 1000)
      instance.add_ip_retention(id: 2, ip_lease_id: 2, lease_time_expired_at: current_time + 2000)
      expect(instance.lease_time_ip_retentions.size).to eq 2
      expect(instance.grace_time_ip_retentions.size).to eq 0

      # exceed 1000 seconds
      allow(Time).to receive(:now).and_return(current_time + 1000)
      expect(instance).to receive(:publish).with(
        Vnet::Event::IP_RETENTION_CONTAINER_EXPIRED_IP_RETENTION,
        id: 1,
        ip_retention_ids: [1]
      )

      instance.check_lease_time_expiration
    end
  end

  describe ".check_grace_time_expiration" do
    it "removes ip_retentions whose grace time is expired" do
      allow(Time).to receive(:now).exactly(2).times.and_return(current_time)

      allow(Vnet::ModelWrappers::IpLease).to receive(:expire).with(1)
      instance.add_ip_retention(id: 1, ip_lease_id: 1, lease_time_expired_at: current_time - 500)
      instance.expire_ip_retentions([1])

      allow(Vnet::ModelWrappers::IpLease).to receive(:expire).with(2)
      instance.add_ip_retention(id: 2, ip_lease_id: 2, lease_time_expired_at: current_time)
      instance.expire_ip_retentions([2])

      # exceed 500 seconds
      allow(Time).to receive(:now).and_return(current_time + 500)
      expect(Vnet::ModelWrappers::IpRetentionContainer).to receive(:remove_ip_retention).with(id: 1, ip_retention_id: 1)

      instance.check_grace_time_expiration
    end
  end

end
