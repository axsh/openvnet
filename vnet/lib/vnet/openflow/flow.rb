# -*- coding: utf-8 -*-

require 'pio'

module Vnet::Openflow

  class Flow

    attr_reader :params

    def initialize(table_id, priority, match, actions, options = {})
      @params = {
        table_id: table_id,
        priority: priority,
        match: match,
        actions: actions,
        options: options
      }
    end

    def to_trema_hash
      trema_hash = {
        table_id: @params[:table_id],
        priority: @params[:priority],
        match: Pio::OpenFlow13::Match.new(@params[:match]),
        instructions: convert_instructions(@params[:actions], @params[:options]),
      }
      trema_hash[:hard_timeout] = @params[:options][:hard_timeout] if @params[:options][:hard_timeout]
      trema_hash[:idle_timeout] = @params[:options][:idle_timeout] if @params[:options][:idle_timeout]
      trema_hash[:cookie] = @params[:options][:cookie] if @params[:options][:cookie]
      trema_hash[:cookie_mask] = @params[:options][:cookie_mask] if @params[:options][:cookie_mask]

      Celluloid.logger.debug "trema_hash: #{trema_hash.inspect}"

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
        instructions << Pio::OpenFlow13::Apply.new(self.convert_actions(actions))
      end

      if options[:metadata]
        instructions << Pio::OpenFlow13::WriteMetadata.new(metadata: options[:metadata],
                                                           metadata_mask: options[:metadata_mask])
      end

      if options[:goto_table]
        instructions << Pio::OpenFlow13::GotoTable.new(options[:goto_table])
      end

      if instructions.empty?
        # Make sure there's always at least one instruction included.
        instructions << Pio::OpenFlow13::Apply.new()
      end

      instructions
    end

    def convert_actions(actions, result = [])
      if actions.class == Hash
        actions.each { |key,arg| result << to_action(key, arg) }
      elsif actions.class == Array
        actions.each { |arg| self.convert_actions(arg, result) }
      else
        raise("Unknown action class: #{actions.class.name}")
      end

      result
    end

    # TODO: SetField needs to consolidate actions.
    def to_action(tag, arg)
      case tag
      when :eth_dst  then Pio::SetDestinationMacAddress.new(arg)
      when :eth_src  then Pio::SetSourceMacAddress.new(arg)
      when :ipv4_dst then Pio::SetDestinationIpAddress.new(arg)
      when :ipv4_src then Pio::SetSourceIpAddress.new(arg)

      when :tcp_dst  then Pio::SetTransportDestinationPort.new(arg)
      when :tcp_src  then Pio::SetTransportSourcePort.new(arg)
      when :udp_dst  then Pio::SetTransportDestinationPort.new(arg)
      when :udp_src  then Pio::SetTransportSourcePort.new(arg)

      when :output then Pio::SendOutPort.new(arg)
      when :tunnel_id then Pio::OpenFlow10::SetVlanVid.new(0x999)
      # when :strip_vlan then Pio::OpenFlow10::StripVlanHeader.new #Trema::Actions::PopVlan.new
      # when :mod_vlan_vid then Trema::Actions::SetField.new(action_set: [Trema::Actions::PushVlan.new(0x8100), Trema::Actions::VlanVid.new(vlan_vid: arg)])
      else
        raise("Unknown action type: #{tag}")
      end
    end

  end

end

