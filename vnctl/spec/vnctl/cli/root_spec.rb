# -*- coding: utf-8 -*-
require 'spec_helper'

describe Vnctl::Cli::Root do
  it "should display error message" do
    content = capture(:stdout) { Vnctl::Cli::Root.start(%w[datapaths]) }
    expect(content).to eq "Commands:
  vnctl datapaths add [OPTIONS] --display-name=DISPLAY_NAME --dpid=DPID --node-id=NODE_ID  # Creates a new datapaths.
  vnctl datapaths del UUID(S)                                                              # Deletes one or more datapaths(s) separated by a space.
  vnctl datapaths help [COMMAND]                                                           # Describe subcommands or one specific subcommand
  vnctl datapaths modify UUID [OPTIONS]                                                    # Modify a datapaths.
  vnctl datapaths networks OPTIONS                                                         # subcommand to manage networks in this datapaths.
  vnctl datapaths route_links OPTIONS                                                      # subcommand to manage route_links in this datapaths.
  vnctl datapaths show [UUID(S)]                                                           # Shows all or a specific set of datapaths(s).

"
  end
end
