require 'spec_helper'

describe Vnet::Services::IpRetentionContainers::Base do
  let(:instance) do
    described_class.new(id: 1, lease_time: 1000, grace_time: 1000).tap(&:try_install)
  end

  let(:current_time) { Time.now }

  describe ".add_ip_retention" do
    context "without released_at" do
      subject do
        instance.add_ip_retention(
          id: 1,
          ip_lease_id: 1,
          leased_at: current_time
        )
        instance
      end

      it { expect(subject.leased_ip_retentions.size).to eq 1 }
      it { expect(subject.released_ip_retentions.size).to eq 0 }
    end

    context "with released_at" do
      subject do
        instance.add_ip_retention(
          id: 1,
          ip_lease_id: 1,
          leased_at: current_time - 1000,
          released_at: current_time,
        )
        instance
      end

      it { expect(subject.leased_ip_retentions.size).to eq 0 }
      it { expect(subject.released_ip_retentions.size).to eq 1 }
    end
  end

  describe ".remove_ip_retention" do
    context "when leased_ip_retentions is present" do
      before do
        instance.add_ip_retention(
          id: 1,
          ip_lease_id: 1,
          leased_at: current_time
        )
      end

      subject do
        instance.remove_ip_retention(1)
        instance
      end

      it { expect(subject.leased_ip_retentions.size).to eq 0 }
    end

    context "when released_ip_retentions is present" do
      before do
        instance.add_ip_retention(
          id: 1,
          ip_lease_id: 1,
          leased_at: current_time - 1000,
          released_at: current_time
        )
      end

      subject do
        instance.remove_ip_retention(1)
        instance
      end

      it { expect(subject.released_ip_retentions.size).to eq 0 }
    end
  end

  describe ".lease_time_expired" do
    it "removes an ip_retention from @leased_ip_retentions" do
      instance.add_ip_retention(
        id: 1,
        ip_lease_id: 1,
        leased_at: current_time - 1000
      )

      expect(instance.leased_ip_retentions.size).to eq 1

      expect(Vnet::ModelWrappers::IpLease).to receive(:expire).with(1)

      instance.lease_time_expired

      expect(instance.leased_ip_retentions.size).to eq 0
      expect(instance.released_ip_retentions.size).to eq 0
    end
  end

  describe ".grace_time_expired" do
    it "removes an ip_retention from @released_ip_retentions" do
      instance.add_ip_retention(
        id: 1,
        ip_lease_id: 1,
        leased_at: current_time - 2000,
        released_at: current_time - 1000
      )

      expect(Vnet::ModelWrappers::IpRetentionContainer).to receive(:remove_ip_retention).with(id: 1, ip_retention_id: 1)
      instance.grace_time_expired

      expect(instance.leased_ip_retentions.size).to eq 0
      expect(instance.released_ip_retentions.size).to eq 0
    end
  end

  describe ".check_lease_time_expiration" do
    it "publishes IP_RETENTION_CONTAINER_LEASE_TIME_EXPIRED" do
      instance.add_ip_retention(id: 1, ip_lease_id: 1, leased_at: current_time - 1000)

      expect(instance).to receive(:publish).with(
        Vnet::Event::IP_RETENTION_CONTAINER_LEASE_TIME_EXPIRED,
        id: 1
      )

      instance.check_lease_time_expiration
    end
  end

  describe ".check_grace_time_expiration" do
    it "publishes IP_RETENTION_CONTAINER_GRACE_TIME_EXPIRED" do
      instance.add_ip_retention(
        id: 2,
        ip_lease_id: 2,
        leased_at: current_time - 2000,
        released_at: current_time - 1000
      )

      expect(instance).to receive(:publish).with(
        Vnet::Event::IP_RETENTION_CONTAINER_GRACE_TIME_EXPIRED,
        id: 1
      )


      instance.check_grace_time_expiration
    end
  end
end
