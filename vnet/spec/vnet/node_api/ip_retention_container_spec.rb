require 'spec_helper'

describe Vnet::NodeApi::IpRetentionContainer do
  let(:node_api_class) { described_class }

  before do
    use_mock_event_handler
  end

  describe ".add_ip_retention" do
    let(:ip_retention_container) { Fabricate(:ip_retention_container) }

    it "adds an ip_retention to the ip_retention_container" do
      current_time = Time.now
      allow(Time).to receive(:now).and_return(current_time)

      ip_retention = node_api_class.add_ip_retention(
        ip_retention_container.id,
        ip_lease_id: 1
      )

      expect(ip_retention.ip_lease_id).to eq 1
      expect(ip_retention.leased_at.to_i).to eq current_time.to_i

      expect(ip_retention_container.ip_retentions.size).to eq 1

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1

      events.first.tap do |event|
        expect(event[:event]).to eq Vnet::Event::IP_RETENTION_CONTAINER_ADDED_IP_RETENTION
        expect(event[:options][:id]).to eq ip_retention_container.id
        expect(event[:options][:ip_retention_id]).to eq ip_retention.id
        expect(event[:options][:ip_lease_id]).to eq 1
        expect(event[:options][:leased_at].to_i).to eq current_time.to_i
      end
    end
  end

  describe ".remove_ip_retention" do
    let(:ip_retention_container) { Fabricate(:ip_retention_container) }
    let(:ip_retention) { Fabricate(:ip_retention, ip_retention_container: ip_retention_container) }

    it "removes an ip_retention from the ip_retention_container" do
      node_api_class.remove_ip_retention(
        ip_retention_container.id,
        ip_retention.id
      )

      expect(ip_retention_container.ip_retentions.size).to eq 0

      events = MockEventHandler.handled_events
      expect(events.size).to eq 1

      events.first.tap do |event|
        expect(event[:event]).to eq Vnet::Event::IP_RETENTION_CONTAINER_REMOVED_IP_RETENTION
        expect(event[:options][:id]).to eq ip_retention_container.id
        expect(event[:options][:ip_retention_id]).to eq ip_retention.id
      end
    end
  end
end
