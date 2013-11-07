# -*- coding: utf-8 -*-

module Vnet::Openflow

  class Flow

    attr_reader :params

    def initialize(table_id, priority, match, actions, options = {})
      @params = {
        :table_id => table_id,
        :priority => priority,
        :match => match,
        :actions => actions,
        :options => options
      }
    end

    def to_trema_hash
      trema_hash = {
        :table_id => @params[:table_id],
        :priority => @params[:priority],
        :match => Trema::Match.new(@params[:match]),
        :instructions => convert_instructions(@params[:actions], @params[:options]),
      }
      trema_hash[:hard_timeout] = @params[:options][:hard_timeout] if @params[:options][:hard_timeout]
      trema_hash[:idle_timeout] = @params[:options][:idle_timeout] if @params[:options][:idle_timeout]
      trema_hash[:cookie] = @params[:options][:cookie] if @params[:options][:cookie]
      trema_hash[:cookie_mask] = @params[:options][:cookie_mask] if @params[:options][:cookie_mask]
      trema_hash
    end

    def ==(flow)
      flow == params
    end

    def self.create(table_id, priority, match, actions, options = {})
      self.new(table_id, priority, match, actions, options)
    end

    def convert_instructions(actions, options)
      instructions = []

      if actions
        instructions << Trema::Instructions::ApplyAction.new(:actions => self.convert_actions(actions))
      end

      if options[:metadata]
        instructions << Trema::Instructions::WriteMetadata.new(:metadata => options[:metadata],
                                                               :metadata_mask => options[:metadata_mask])
      end

      if options[:goto_table]
        instructions << Trema::Instructions::GotoTable.new(:table_id => options[:goto_table])
      end

      if instructions.empty?
        # Make sure there's always at least one instruction included.
        instructions << Trema::Instructions::ApplyAction.new(:actions => [])
      end

      instructions
    end

    def convert_actions(actions, result = [])
      if actions.class == Hash
        actions.each { |key,arg| result << to_action(key, arg) }
      elsif actions.class == Array
        actions.each { |arg| self.convert_actions(arg, result) }
      else
        raise("Unknown action class: #{actions.class.name}.")
      end

      result
    end

    def to_action(tag, arg)
      case tag
      when :eth_dst then Trema::Actions::SetField.new(:action_set => [Trema::Actions::EthDst.new(:mac_address => arg)])
      when :eth_src then Trema::Actions::SetField.new(:action_set => [Trema::Actions::EthSrc.new(:mac_address => arg)])
      when :normal then Trema::Actions::SendOutPort.new(:port_number => OFPP_NORMAL)
      when :output then Trema::Actions::SendOutPort.new(:port_number => arg)
      when :tunnel_id then Trema::Actions::SetField.new(:action_set => [Trema::Actions::TunnelId.new(:tunnel_id => arg)])
      when :strip_vlan then Trema::Actions::PopVlan.new if arg == true # TODO refactoring
      when :mod_vlan_vid then Trema::Actions::SetField.new(:action_set => [Trema::Actions::PushVlan.new(0x8100), Trema::Actions::VlanVid.new(:vlan_vid => arg)])
      #when :mod_vlan_vid then Trema::Actions::VlanVid.new(:vlan_vid => arg)
      else
        raise("Unknown action type.")
      end
    end

  end

end

