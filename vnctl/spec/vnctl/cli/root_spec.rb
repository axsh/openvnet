# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnctl::Cli::Root do
  it "should display error message" do
    content = capture(:stdout) { Vnctl::Cli::Root.start }
    expect(content).to eq "Commands:
  vnctl datapaths          # Operations for datapaths.
  vnctl dns_services       # Operations for dns_services.
  vnctl help [COMMAND]     # Describe available commands or one specific command
  vnctl interfaces         # Operations for interfaces.
  vnctl ip_leases          # Operations for ip leases.
  vnctl ip_range_groups    # Operations for ip ranges.
  vnctl lease_policies     # Operations for lease policies.
  vnctl mac_leases         # Operations for mac leases.
  vnctl network_services   # Operations for network services.
  vnctl networks           # Operations for networks.
  vnctl route_links        # Operations for route links.
  vnctl routes             # Operations for routes.
  vnctl security_groups    # Operations for security groups.
  vnctl translations       # Operations for translations.
  vnctl vlan_translations  # Operations for vlan translations.

"
  end
end
