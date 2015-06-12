# -*- coding: utf-8 -*-
require_relative "spec_helper"

describe "lease_policy" do
  it "vm1 is reachable to vm3" do
    expect(vm1).to be_reachable_to(vm3)
  end

  it "vm1 is reachable to vm5" do
    expect(vm1).to be_reachable_to(vm5)
  end

  it "the ip lease of vm1 is going to be released 5 minutes after it is leased" do
    ip_retention_container = Vnspec::Models::IpRetentionContainer.find("irc-1")
    ip_retentions = ip_retention_container.ip_retentions
    released_at = ip_retentions.first.leased_at + ip_retention_container.lease_time

    sleep_time = released_at - Time.now + 70
    puts "wair for ip_lease to be released(#{sleep_time} sec)"
    sleep(sleep_time)

    ip_retentions = ip_retention_container.ip_retentions(reload: true)
    expect(ip_retentions.first.released_at.to_i).to be_within(70).of(released_at.to_i)

    sleep_time = released_at + ip_retention_container.grace_time - Time.now + 70
    puts "wair for ip_lease to be destroyed(#{sleep_time} sec)"
    sleep(sleep_time)

    ip_retentions = ip_retention_container.ip_retentions(reload: true)
    expect(ip_retentions).to be_empty

    expect(vm1).not_to be_reachable_to(vm3)
    expect(vm1).not_to be_reachable_to(vm5)
  end
end
