# -*- coding: utf-8 -*-

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
      # Celluloid.logger.debug "trema_hash.params: #{@params.inspect}"

      trema_hash = {
        table_id: @params[:table_id],
        priority: @params[:priority],
        transaction_id: rand(0xffffffff),
        match: Pio::OpenFlow13::Match.new(@params[:match]),
        instructions: convert_instructions(@params[:actions], @params[:options]),
      }

      @params[:options].tap { |options|
        trema_hash[:hard_timeout] = options[:hard_timeout] if options[:hard_timeout]
        trema_hash[:idle_timeout] = options[:idle_timeout] if options[:idle_timeout]
        trema_hash[:cookie] = options[:cookie] if options[:cookie]
        trema_hash[:cookie_mask] = options[:cookie_mask] if options[:cookie_mask]
      }

      # Celluloid.logger.debug "trema_hash.result: #{trema_hash.inspect}"

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

    def to_action(tag, arg)
      case tag
      when :destination_mac_address  then Pio::OpenFlow13::SetDestinationMacAddress.new(arg)
      when :source_mac_address  then Pio::OpenFlow13::SetSourceMacAddress.new(arg)
      when :ipv4_destination_address then Pio::OpenFlow13::SetDestinationIpAddress.new(arg)
      when :ipv4_source_address then Pio::OpenFlow13::SetSourceIpAddress.new(arg)

      when :output then Pio::OpenFlow13::SendOutPort.new(arg)
      when :tunnel_id then Pio::OpenFlow13::SetTunnelId.new(arg)
      else
        raise("Unknown action type: #{tag}")
      end
    end

  end
end

