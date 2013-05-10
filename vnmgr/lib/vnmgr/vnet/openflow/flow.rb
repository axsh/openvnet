# -*- coding: utf-8 -*-

module Vnmgr::VNet::Openflow

  module Flow

    def self.create(table_id, priority, match, actions, options = {})
      trema_hash = {
        :table_id => table_id,
        :priority => priority,
        :match => Trema::Match.new(match),
        :instructions => self.convert_instructions(actions, options),
      }
      trema_hash[:hard_timeout] = options[:hard_timeout] if options[:hard_timeout]
      trema_hash[:idle_timeout] = options[:idle_timeout] if options[:idle_timeout]
      trema_hash[:cookie] = options[:cookie] if options[:cookie]
      trema_hash[:cookie_mask] = options[:cookie_mask] if options[:cookie_mask]
      trema_hash
    end

    private

    def self.convert_instructions(actions, options)
      instructions = []
      instructions << Trema::Instructions::ApplyAction.new(:actions => self.convert_actions(actions)) if actions

      if options[:metadata]
        instructions << Trema::Instructions::WriteMetadata.new(:metadata => options[:metadata],
                                                               :metadata_mask => options[:metadata_mask])
      end

      instructions << Trema::Instructions::GotoTable.new(:table_id => options[:goto_table]) if options[:goto_table]
      instructions
    end

    def self.convert_actions(actions, result = [])
      if actions.class == Hash
        actions.each { |key,arg| result << to_action(key, arg) }
      elsif actions.class == Array
        actions.each { |arg| self.convert_actions(arg, result) }
      else
        raise("Unknown action class: #{actions.class.name}.")
      end

      result
    end

    def self.to_action(tag, arg)
      case tag
      when :output then Trema::Actions::SendOutPort.new(arg)
      else
        raise("Unknown action type.")
      end
    end

  end

end

