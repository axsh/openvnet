require 'spec_helper'

describe Sequel::Plugins::ParanoiaWithUniqueConstraint do
  describe "destroy" do
    it "enables soft deletion of models with unique constraint" do
      dp1 = Vnet::Models::DatapathNetwork.create(
        datapath_id: 1,
        network_id: 1
      )
      dp1.destroy

      dp2 = Vnet::Models::DatapathNetwork.create(
        datapath_id: 1,
        network_id: 1
      )
      dp2.destroy

      dp3 = Vnet::Models::DatapathNetwork.create(
        datapath_id: 1,
        network_id: 1
      )
      dp3.destroy

      expect(Vnet::Models::DatapathNetwork.count).to eq 0
      expect(Vnet::Models::DatapathNetwork.with_deleted.count).to eq 3
    end
  end
end
