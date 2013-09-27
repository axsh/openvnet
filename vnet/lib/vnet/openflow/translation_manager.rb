# -*- coding: utf-8 -*-

module Vnet::Openflow
  class TranslationManager < Manager
    include Celluloid::Logger
    include FlowHelpers
    include Vnet::Event::Dispatchable

    def initialize(dp)
      @datapath = dp
    end

    def update
      flows = []
      graphs = Vnet::ModelWrappers::VlanTranslation.batch.all.commit
      graphs.each do |g|
        metadata = nil

        if g.network_id
          metadata = md_create(:network => g.network_id)
        else
          raise("no network id found: #{g.inspect}")
        end

        if g.vlan_id.nil?
          if g.mac_address.nil?
            raise("either mac_address of vlan_id is required.")
          else
            flows << Flow.create(TABLE_VLAN_TRANSLATION, 2, {
                                  :eth_src => Trema::Mac.new(g.mac_address)
                                 }, nil, metadata.merge({:goto_table => TABLE_NETWORK_SRC_CLASSIFIER}))
          end
        else
          flows << Flow.create(TABLE_VLAN_TRANSLATION, 2, {
                                :vlan_vid => g.vlan_id
                               }, {:strip_vlan => true}, metadata.merge({:goto_table => TABLE_NETWORK_SRC_CLASSIFIER}))
        end

        @datapath.add_flows(flows)
      end
    end
  end
end
